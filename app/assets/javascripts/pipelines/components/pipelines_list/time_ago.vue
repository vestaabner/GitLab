<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { durationTimeFormatted } from '~/lib/utils/datetime_utility';
import timeagoMixin from '~/vue_shared/mixins/timeago';

export default {
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: { GlIcon },
  mixins: [timeagoMixin],
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  computed: {
    duration() {
      return this.pipeline?.details?.duration;
    },
    finishedTime() {
      return this.pipeline?.details?.finished_at;
    },
    skipped() {
      return this.pipeline?.details?.status?.label === 'skipped';
    },
    stuck() {
      return this.pipeline.flags.stuck;
    },
    durationFormatted() {
      return durationTimeFormatted(this.duration);
    },
    showInProgress() {
      return !this.duration && !this.finishedTime && !this.skipped;
    },
    showSkipped() {
      return !this.duration && !this.finishedTime && this.skipped;
    },
  },
};
</script>
<template>
  <div class="gl-display-block">
    <span v-if="showInProgress" data-testid="pipeline-in-progress">
      <gl-icon v-if="stuck" name="warning" class="gl-mr-2" :size="12" data-testid="warning-icon" />
      <gl-icon
        v-else
        name="hourglass"
        class="gl-vertical-align-baseline! gl-mr-2"
        :size="12"
        data-testid="hourglass-icon"
      />
      {{ s__('Pipeline|In progress') }}
    </span>

    <span v-if="showSkipped" data-testid="pipeline-skipped">
      <gl-icon name="status_skipped_borderless" class="gl-mr-2" :size="16" />
      {{ s__('Pipeline|Skipped') }}
    </span>

    <p v-if="duration" class="duration">
      <gl-icon name="timer" class="gl-vertical-align-baseline!" :size="12" />
      {{ durationFormatted }}
    </p>

    <p v-if="finishedTime" class="finished-at d-none d-md-block">
      <gl-icon name="calendar" class="gl-vertical-align-baseline!" :size="12" />

      <time
        v-gl-tooltip
        :title="tooltipTitle(finishedTime)"
        :datetime="finishedTime"
        data-placement="top"
        data-container="body"
      >
        {{ timeFormatted(finishedTime) }}
      </time>
    </p>
  </div>
</template>
