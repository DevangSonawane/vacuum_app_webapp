String fmtRevenue(num v) {
  if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
  if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}k';
  return '₹${v.toStringAsFixed(0)}';
}
