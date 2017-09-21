module Ci
  class PipelineScheduleVariable < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include HasVariable

    belongs_to :pipeline_schedule

    validates :key, uniqueness: { scope: :pipeline_schedule_id }
  end
end
