<script>
export default {
  props: {
    expanded: {
      type: Boolean,
      required: true,
    },
  },
  watch: {
    expanded(value) {
      const layoutPageEl = document.querySelector('.layout-page');

      if (layoutPageEl) {
        layoutPageEl.classList.toggle('right-sidebar-expanded', value);
        layoutPageEl.classList.toggle('right-sidebar-collapsed', !value);
        layoutPageEl.classList.toggle('issuable-bulk-update-sidebar', !value);
      }
    },
  },
};
</script>

<template>
  <aside
    :class="{ 'right-sidebar-expanded': expanded, 'right-sidebar-collapsed': !expanded }"
    class="issues-bulk-update right-sidebar"
    aria-live="polite"
  >
    <div
      class="gl-display-flex gl-justify-content-space-between gl-p-4 gl-border-b-1 gl-border-b-solid gl-border-gray-100"
    >
      <slot name="bulk-edit-actions"></slot>
    </div>
    <slot name="sidebar-items"></slot>
  </aside>
</template>
