<script>
import { GlIcon } from '@gitlab/ui';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';

export default {
  name: 'HistoryItem',
  components: {
    GlIcon,
    TimelineEntryItem,
  },
  props: {
    icon: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <timeline-entry-item class="system-note note-wrapper">
    <div class="timeline-icon">
      <gl-icon :name="icon" />
    </div>
    <div class="timeline-content">
      <div class="note-header">
        <div class="note-header-info">
          <slot></slot>
        </div>
      </div>
      <div class="note-body">
        <slot name="body"></slot>
      </div>
    </div>
  </timeline-entry-item>
</template>
