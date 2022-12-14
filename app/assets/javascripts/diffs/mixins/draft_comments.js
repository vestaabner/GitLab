import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters('batchComments', [
      'shouldRenderDraftRow',
      'shouldRenderParallelDraftRow',
      'draftsForLine',
      'draftsForFile',
      'hasParallelDraftLeft',
      'hasParallelDraftRight',
    ]),
    imageDiscussions() {
      return this.diffFile.discussions.concat(this.draftsForFile(this.diffFile.file_hash));
    },
  },
};
