# frozen_string_literal: true

class BackfillIntegrationsEnableSslVerification < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  MIGRATION = 'BackfillIntegrationsEnableSslVerification'
  INTERVAL = 5.minutes
  BATCH_SIZE = 1_000

  class Integration < MigrationRecord
    include EachBatch
    include IgnorableColumns

    self.table_name = :integrations
    self.inheritance_column = :_type_disabled

    ignore_column :template, remove_with: '15.0', remove_after: '2022-04-22'
    ignore_column :type, remove_with: '15.0', remove_after: '2022-04-22'
    ignore_column :properties, remove_with: '15.1', remove_after: '2022-05-22'

    scope :affected, -> do
      where(type_new: %w[Integrations::DroneCi Integrations::Teamcity]).where.not(encrypted_properties: nil)
    end

    attr_encrypted :properties,
                  mode: :per_attribute_iv,
                  key: Settings.attr_encrypted_db_key_base_32,
                  algorithm: 'aes-256-gcm',
                  marshal: true,
                  marshaler: ::Gitlab::Json,
                  encode: false,
                  encode_iv: false

    # Handle assignment of props with symbol keys.
    # To do this correctly, we need to call the method generated by attr_encrypted.
    alias_method :attr_encrypted_props=, :properties=
    private :attr_encrypted_props=

    def properties=(props)
      self.attr_encrypted_props = props&.with_indifferent_access&.freeze
    end
  end

  def up
    queue_background_migration_jobs_by_range_at_intervals(
      Integration.affected,
      MIGRATION,
      INTERVAL,
      batch_size: BATCH_SIZE,
      track_jobs: true
    )
  end

  def down
  end
end
