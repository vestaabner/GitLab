# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryImportWorker do
  describe '#perform' do
    let(:project) { create(:project, :import_scheduled) }
    let(:import_state) { project.import_state }

    context 'when worker was reset without cleanup' do
      it 'imports the project successfully' do
        jid = '12345678'
        started_project = create(:project)
        started_import_state = create(:import_state, :started, project: started_project, jid: jid)

        allow(subject).to receive(:jid).and_return(jid)

        expect_next_instance_of(Projects::ImportService) do |instance|
          expect(instance).to receive(:execute).and_return({ status: :ok })
        end

        # Works around https://github.com/rspec/rspec-mocks/issues/910
        expect(Project).to receive(:find).with(started_project.id).and_return(started_project)
        expect(started_project.repository).to receive(:expire_emptiness_caches)
        expect(started_project.wiki.repository).to receive(:expire_emptiness_caches)
        expect(started_import_state).to receive(:finish)

        subject.perform(started_project.id)
      end
    end

    context 'when the import was successful' do
      it 'imports a project' do
        expect_next_instance_of(Projects::ImportService) do |instance|
          expect(instance).to receive(:execute).and_return({ status: :ok })
        end

        # Works around https://github.com/rspec/rspec-mocks/issues/910
        expect(Project).to receive(:find).with(project.id).and_return(project)
        expect(project.repository).to receive(:expire_emptiness_caches)
        expect(project.wiki.repository).to receive(:expire_emptiness_caches)
        expect(import_state).to receive(:finish)

        subject.perform(project.id)
      end
    end

    context 'when the import has failed' do
      it 'updates the error on Import/Export & hides credentials from import URL' do
        import_url = 'https://user:pass@test.com/root/repoC.git/'
        error = "#{import_url} not found"

        import_state.update!(jid: '123')
        project.update!(import_type: 'gitlab_project')

        expect_next_instance_of(Projects::ImportService) do |instance|
          expect(instance).to receive(:track_start_import).and_raise(StandardError, error)
        end

        expect { subject.perform(project.id) }.not_to raise_error

        import_state.reload
        expect(import_state.jid).to eq('123')
        expect(import_state.status).to eq('failed')
        expect(import_state.last_error).to include("[FILTERED] not found")
        expect(import_state.last_error).not_to include(import_url)
      end
    end

    context 'when using an asynchronous importer' do
      it 'does not mark the import process as finished' do
        service = double(:service)

        allow(Projects::ImportService)
          .to receive(:new)
          .and_return(service)

        allow(service)
          .to receive(:execute)
          .and_return(true)

        allow(service)
          .to receive(:async?)
          .and_return(true)

        expect_next_instance_of(ProjectImportState) do |instance|
          expect(instance).not_to receive(:finish)
        end

        subject.perform(project.id)
      end
    end
  end
end
