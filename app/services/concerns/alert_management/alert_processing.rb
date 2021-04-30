# frozen_string_literal: true

module AlertManagement
  # Module to support the processing of new alert payloads
  # from various sources. Payloads may be for new alerts,
  # existing alerts, or acting as a resolving alert.
  #
  # Performs processing-related tasks, such as creating system
  # notes, creating or resolving related issues, and notifying
  # stakeholders of the alert.
  #
  # Requires #project [Project] and #payload [Hash] methods
  # to be defined.
  module AlertProcessing
    include BaseServiceUtility
    include Gitlab::Utils::StrongMemoize
    include ::IncidentManagement::Settings

    # Updates or creates alert from payload for project
    # including system notes
    def process_alert
      if alert.persisted?
        process_existing_alert
      else
        process_new_alert
      end
    end

    # Creates or closes issue for alert and notifies stakeholders
    def complete_post_processing_tasks
      process_incident_issues if process_issues?
      send_alert_email if send_email? && notifying_alert?
    end

    def process_existing_alert
      if resolving_alert?
        process_resolved_alert
      else
        process_firing_alert
      end
    end

    def process_resolved_alert
      SystemNoteService.log_resolving_alert(alert, alert_source)

      return unless auto_close_incident?

      if alert.resolve(incoming_payload.ends_at)
        SystemNoteService.change_alert_status(alert, User.alert_bot)

        close_issue(alert.issue)
      else
        logger.warn(
          message: 'Unable to update AlertManagement::Alert status to resolved',
          project_id: project.id,
          alert_id: alert.id
        )
      end
    end

    def process_firing_alert
      alert.register_new_event!
    end

    def close_issue(issue)
      return if issue.blank? || issue.closed?

      ::Issues::CloseService
        .new(project, User.alert_bot)
        .execute(issue, system_note: false)

      SystemNoteService.auto_resolve_prometheus_alert(issue, project, User.alert_bot) if issue.reset.closed?
    end

    def process_new_alert
      if alert.save
        alert.execute_services
        SystemNoteService.create_new_alert(alert, alert_source)
      else
        logger.warn(
          message: "Unable to create AlertManagement::Alert from #{alert_source}",
          project_id: project.id,
          alert_errors: alert.errors.messages
        )
      end
    end

    def process_incident_issues
      return if alert.issue || alert.resolved?

      ::IncidentManagement::ProcessAlertWorkerV2.perform_async(alert.id)
    end

    def send_alert_email
      notification_service
        .async
        .prometheus_alerts_fired(project, [alert])
    end

    def incoming_payload
      strong_memoize(:incoming_payload) do
        Gitlab::AlertManagement::Payload.parse(project, payload.to_h, integration: integration)
      end
    end

    def alert
      strong_memoize(:alert) do
        find_existing_alert || build_new_alert
      end
    end

    def find_existing_alert
      return unless incoming_payload.gitlab_fingerprint

      AlertManagement::Alert.not_resolved.for_fingerprint(project, incoming_payload.gitlab_fingerprint).first
    end

    def build_new_alert
      AlertManagement::Alert.new(**incoming_payload.alert_params, ended_at: nil)
    end

    def resolving_alert?
      incoming_payload.ends_at.present?
    end

    def notifying_alert?
      alert.triggered? || alert.resolved?
    end

    def alert_source
      alert.monitoring_tool
    end

    def logger
      @logger ||= Gitlab::AppLogger
    end
  end
end

AlertManagement::AlertProcessing.prepend_ee_mod
