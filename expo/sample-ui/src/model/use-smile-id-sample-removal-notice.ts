/// The confirmation a removal reports, in the shared package so four shells cannot word it differently.
export const smileIDSampleRemovalNotice = (count: number) => ({
  message:
    count === 1
      ? '1 verification hidden from App list'
      : `${count} verifications hidden from App list`,
  actionLabel: 'Undo',
});
