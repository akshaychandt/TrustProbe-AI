import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:trustprobe_ai/models/scan_result.dart';

/// SearchHistoryTable - Displays previous URL scans in a responsive table
class SearchHistoryTable extends StatelessWidget {
  final Stream<List<ScanResult>> scansStream;
  final Function(ScanResult)? onScanTap;

  const SearchHistoryTable({
    super.key,
    required this.scansStream,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScanResult>>(
      stream: scansStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState();
        }

        return _buildTable(snapshot.data!);
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00d2ff)),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error loading history: $error',
              style: GoogleFonts.inter(
                color: Colors.red.shade300,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text(
            'No previous searches',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.white60,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzed URLs will appear here',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<ScanResult> scans) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout
          if (constraints.maxWidth < 600) {
            return _buildMobileList(scans);
          } else {
            return _buildDesktopTable(scans);
          }
        },
      ),
    );
  }

  Widget _buildMobileList(List<ScanResult> scans) {
    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: scans.length,
      separatorBuilder: (context, index) =>
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
      itemBuilder: (context, index) {
        final scan = scans[index];
        return _buildMobileListItem(scan);
      },
    );
  }

  Widget _buildMobileListItem(ScanResult scan) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return InkWell(
      onTap: onScanTap != null ? () => onScanTap!(scan) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              scan.url,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRiskBadge(scan.riskScore),
                _buildClassificationBadge(scan.classification),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dateFormat.format(scan.timestamp),
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<ScanResult> scans) {
    return Table(
      border: TableBorder(
        horizontalInside: BorderSide(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      columnWidths: {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(2),
      },
      children: [
        // Header
        TableRow(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          children: [
            _buildTableHeader('URL'),
            _buildTableHeader('Risk Score'),
            _buildTableHeader('Classification'),
            _buildTableHeader('Date/Time'),
          ],
        ),
        // Rows
        ...scans.map((scan) => _buildTableRow(scan)),
      ],
    );
  }

  TableCell _buildTableHeader(String text) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(ScanResult scan) {
    final dateFormat = DateFormat('MMM dd, yyyy\nHH:mm');

    return TableRow(
      decoration: onScanTap != null
          ? BoxDecoration(color: Colors.transparent)
          : null,
      children: [
        TableCell(
          child: InkWell(
            onTap: onScanTap != null ? () => onScanTap!(scan) : null,
            hoverColor: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  if (onScanTap != null)
                    Icon(
                      Icons.touch_app,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  if (onScanTap != null) const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scan.url,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: InkWell(
            onTap: onScanTap != null ? () => onScanTap!(scan) : null,
            hoverColor: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _buildRiskBadge(scan.riskScore),
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: InkWell(
            onTap: onScanTap != null ? () => onScanTap!(scan) : null,
            hoverColor: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: _buildClassificationBadge(scan.classification),
            ),
          ),
        ),
        TableCell(
          child: InkWell(
            onTap: onScanTap != null ? () => onScanTap!(scan) : null,
            hoverColor: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                dateFormat.format(scan.timestamp),
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white60),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskBadge(int riskScore) {
    Color color;
    if (riskScore <= 30) {
      color = Color(0xFF00d4aa);
    } else if (riskScore <= 70) {
      color = Color(0xFFffb700);
    } else {
      color = Color(0xFFff4757);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$riskScore%',
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildClassificationBadge(String classification) {
    Color color;
    IconData icon;

    if (classification == 'Safe') {
      color = Color(0xFF00d4aa);
      icon = Icons.check_circle;
    } else if (classification == 'Suspicious') {
      color = Color(0xFFffb700);
      icon = Icons.warning;
    } else {
      color = Color(0xFFff4757);
      icon = Icons.dangerous;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          classification,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
