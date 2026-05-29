#!/usr/bin/env Rscript
# plot_paf_coverage.R
# Per-chromosome PAF coverage: merge overlapping alignments, build a summary
# table, and render a gggenomes coverage plot.
#
# Usage:
#   Rscript plot_paf_coverage.R <input.paf> <out_prefix> [side]
#     side = "target" (default) or "query"
#
# Output:
#   <out_prefix>_coverage.tsv  -- per-chromosome covered bp / % covered
#   <out_prefix>_coverage.pdf  -- gggenomes coverage map
#   <out_prefix>_coverage.png  -- same, raster

suppressPackageStartupMessages({
  library(gggenomes)
  library(dplyr)
  library(tidyr)
  library(IRanges)
  library(ggplot2)
  library(readr)
})

# ---- args ----
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("Usage: Rscript plot_paf_coverage.R <input.paf> <out_prefix> [target|query]")
}
paf_path   <- args[1]
out_prefix <- args[2]
side       <- if (length(args) >= 3) args[3] else "target"
stopifnot(side %in% c("target", "query"))

# Pick which columns to summarise over.
# gggenomes::read_paf gives: seq_id/start/end/length = QUERY,
#                            seq_id2/start2/end2/length2 = TARGET.
if (side == "target") {
  name_col <- "seq_id2"; start_col <- "start2"; end_col <- "end2"; len_col <- "length2"
} else {
  name_col <- "seq_id";  start_col <- "start";  end_col <- "end";  len_col <- "length"
}

# ---- read PAF ----
message("Reading ", paf_path)
paf <- read_paf(paf_path)

# Rename to neutral names for the rest of the script
paf <- paf %>%
  rename(chrom  = !!name_col,
         astart = !!start_col,
         aend   = !!end_col,
         clen   = !!len_col)

# ---- per-chromosome merged coverage intervals ----
# IRanges::reduce() merges overlapping alignment intervals so each base is counted once.
merged <- paf %>%
  group_by(chrom) %>%
  group_modify(~ {
    ir <- IRanges::reduce(IRanges(.x$astart, .x$aend))
    tibble(start = start(ir), end = end(ir), width = width(ir))
  }) %>%
  ungroup()

# ---- summary table ----
chrom_lens <- paf %>% distinct(chrom, clen)

cov_tbl <- merged %>%
  group_by(chrom) %>%
  summarise(n_blocks   = n(),
            covered_bp = sum(width),
            .groups = "drop") %>%
  right_join(chrom_lens, by = "chrom") %>%
  mutate(covered_bp = tidyr::replace_na(covered_bp, 0L),
         n_blocks   = tidyr::replace_na(n_blocks, 0L),
         pct_covered = covered_bp / clen * 100) %>%
  left_join(
    paf %>% group_by(chrom) %>%
      summarise(n_alignments = n(),
                mean_mapq    = mean(map_quality, na.rm = TRUE),
                .groups = "drop"),
    by = "chrom"
  ) %>%
  arrange(desc(clen))

write_tsv(cov_tbl, paste0(out_prefix, "_coverage.tsv"))
message("Wrote ", out_prefix, "_coverage.tsv")
print(cov_tbl, n = 25)

# ---- gggenomes plot ----
# gggenomes wants:
#   seqs:  bin_id, seq_id, length   (one row per chromosome)
#   feats: seq_id, start, end       (one row per covered block)
seqs <- chrom_lens %>%
  transmute(bin_id = side, seq_id = chrom, length = clen) %>%
  arrange(desc(length))

feats <- merged %>%
  transmute(seq_id = chrom, start = start, end = end)

# Order chromosomes by length (largest at top)
seqs$seq_id  <- factor(seqs$seq_id,  levels = seqs$seq_id)
feats$seq_id <- factor(feats$seq_id, levels = levels(seqs$seq_id))

p <- gggenomes(seqs = seqs, feats = list(coverage = feats)) +
  geom_seq(colour = "grey80", linewidth = 1.2) +              # chromosome backbone
  geom_bin_label(size = 3) +                                  # chromosome labels
  geom_feat(data = feats(coverage),                           # covered intervals
            aes(colour = NULL),
            colour = "steelblue", linewidth = 3) +
  scale_x_bp(suffix = "b") +
  labs(title    = paste0("PAF coverage on ", side, " sequences"),
       subtitle = paste0(basename(paf_path),
                         "  |  blue = covered by >=1 alignment (overlaps merged)"),
       x = NULL, y = NULL) +
  theme(plot.title = element_text(face = "bold"))

# Height scales with number of chromosomes
h <- max(3, 0.25 * nrow(seqs) + 1.5)

ggsave(paste0(out_prefix, "_coverage.pdf"), p, width = 10, height = h, limitsize = FALSE)
ggsave(paste0(out_prefix, "_coverage.png"), p, width = 10, height = h, dpi = 150, limitsize = FALSE)
message("Wrote ", out_prefix, "_coverage.{pdf,png}")