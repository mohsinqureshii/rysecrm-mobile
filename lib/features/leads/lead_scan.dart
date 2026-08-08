/// Parsers that turn scanned/pasted contact data into structured lead fields.
///
/// On a device the camera provides the raw text: a QR/vCard payload, or the
/// OCR transcription of a business card. Both feed the same pure parsers here,
/// so the capture flow is identical whether the text comes from the camera or
/// is pasted in. Keeping the parsing pure makes it unit-testable.
library;

class ParsedLead {
  const ParsedLead({
    this.firstName = '',
    this.lastName = '',
    this.company = '',
    this.title = '',
    this.email = '',
    this.phone = '',
    this.website = '',
    this.city = '',
    this.country = '',
  });

  final String firstName;
  final String lastName;
  final String company;
  final String title;
  final String email;
  final String phone;
  final String website;
  final String city;
  final String country;

  bool get isEmpty =>
      firstName.isEmpty &&
      lastName.isEmpty &&
      company.isEmpty &&
      email.isEmpty &&
      phone.isEmpty;
}

final _emailRe = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
final _phoneRe = RegExp(r'(\+?\d[\d\s().-]{6,}\d)');
final _urlRe = RegExp(
  r'((https?://)?(www\.)?[a-z0-9-]+\.[a-z]{2,}(/[^\s]*)?)',
  caseSensitive: false,
);
const _titleKeywords = [
  'ceo', 'cto', 'cfo', 'coo', 'cmo', 'vp', 'vice president', 'president',
  'director', 'manager', 'head', 'lead', 'chief', 'founder', 'owner',
  'officer', 'engineer', 'consultant', 'partner', 'principal', 'analyst',
  'account executive', 'sales', 'marketing',
];
const _companyKeywords = [
  'inc', 'inc.', 'llc', 'ltd', 'ltd.', 'corp', 'corp.', 'co.', 'company',
  'technologies', 'technology', 'labs', 'group', 'solutions', 'systems',
  'consulting', 'partners', 'ventures', 'holdings', 'gmbh', 'pvt',
];

void _splitName(ParsedLeadBuilder b, String full) {
  final parts = full.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return;
  b.firstName = parts.first;
  if (parts.length > 1) b.lastName = parts.sublist(1).join(' ');
}

class ParsedLeadBuilder {
  String firstName = '';
  String lastName = '';
  String company = '';
  String title = '';
  String email = '';
  String phone = '';
  String website = '';
  String city = '';
  String country = '';

  ParsedLead build() => ParsedLead(
        firstName: firstName,
        lastName: lastName,
        company: company,
        title: title,
        email: email,
        phone: phone,
        website: website,
        city: city,
        country: country,
      );
}

/// Parse a vCard / QR-code payload (VCARD or `MECARD:` styles).
ParsedLead parseVCard(String payload) {
  final b = ParsedLeadBuilder();
  final text = payload.trim();

  if (text.toUpperCase().startsWith('MECARD:')) {
    // MECARD:N:Lee,Jordan;ORG:Acme;TEL:+1..;EMAIL:a@b.com;URL:..;;
    final body = text.substring(text.indexOf(':') + 1);
    for (final field in body.split(';')) {
      final idx = field.indexOf(':');
      if (idx == -1) continue;
      final key = field.substring(0, idx).toUpperCase();
      final value = field.substring(idx + 1).trim();
      if (value.isEmpty) continue;
      switch (key) {
        case 'N':
          final np = value.split(',');
          b.lastName = np.isNotEmpty ? np[0].trim() : '';
          b.firstName = np.length > 1 ? np[1].trim() : '';
        case 'ORG':
          b.company = value;
        case 'TEL':
          b.phone = value;
        case 'EMAIL':
          b.email = value;
        case 'URL':
          b.website = value;
      }
    }
    return b.build();
  }

  for (final rawLine in text.split(RegExp(r'\r?\n'))) {
    final line = rawLine.trim();
    final idx = line.indexOf(':');
    if (idx == -1) continue;
    final key = line.substring(0, idx).split(';').first.toUpperCase();
    final value = line.substring(idx + 1).trim();
    if (value.isEmpty) continue;
    switch (key) {
      case 'FN':
        if (b.firstName.isEmpty) _splitName(b, value);
      case 'N':
        // Family;Given;Additional;Prefix;Suffix
        final np = value.split(';');
        if (np.isNotEmpty && np[0].trim().isNotEmpty) {
          b.lastName = np[0].trim();
          b.firstName = np.length > 1 ? np[1].trim() : b.firstName;
        }
      case 'ORG':
        b.company = value.split(';').first.trim();
      case 'TITLE':
        b.title = value;
      case 'EMAIL':
        b.email = value;
      case 'TEL':
        b.phone = value;
      case 'URL':
        b.website = value;
      case 'ADR':
        // ;;street;city;region;postal;country
        final ap = value.split(';');
        if (ap.length > 3 && ap[3].trim().isNotEmpty) b.city = ap[3].trim();
        if (ap.isNotEmpty && ap.last.trim().isNotEmpty) {
          b.country = ap.last.trim();
        }
    }
  }
  return b.build();
}

/// Heuristically parse the OCR text of a business card.
ParsedLead parseBusinessCard(String raw) {
  final b = ParsedLeadBuilder();
  final lines = raw
      .split(RegExp(r'\r?\n'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return b.build();

  final consumed = <int>{};

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final lower = line.toLowerCase();

    final email = _emailRe.firstMatch(line)?.group(0);
    if (email != null && b.email.isEmpty) {
      b.email = email;
      consumed.add(i);
      continue;
    }
    if (b.phone.isEmpty &&
        RegExp(r'(tel|phone|mob|cell|t:|m:|p:)', caseSensitive: false)
                .hasMatch(lower) ||
        (b.phone.isEmpty && _phoneRe.hasMatch(line) && email == null)) {
      final phone = _phoneRe.firstMatch(line)?.group(0);
      if (phone != null && phone.replaceAll(RegExp(r'\D'), '').length >= 7) {
        b.phone = phone.trim();
        consumed.add(i);
        continue;
      }
    }
    if (b.website.isEmpty && email == null) {
      final url = _urlRe.firstMatch(line)?.group(0);
      if (url != null && !url.contains('@') && url.contains('.')) {
        b.website = url;
        consumed.add(i);
        continue;
      }
    }
    if (b.title.isEmpty &&
        _titleKeywords.any((k) => RegExp('\\b$k\\b').hasMatch(lower))) {
      b.title = line;
      consumed.add(i);
      continue;
    }
    if (b.company.isEmpty &&
        _companyKeywords.any((k) => RegExp('\\b${RegExp.escape(k)}')
            .hasMatch(lower))) {
      b.company = line;
      consumed.add(i);
      continue;
    }
  }

  // Name: first unconsumed line that looks like a person's name.
  for (var i = 0; i < lines.length; i++) {
    if (consumed.contains(i)) continue;
    final words = lines[i].split(RegExp(r'\s+'));
    if (words.length >= 2 && words.length <= 4 && !_emailRe.hasMatch(lines[i])) {
      _splitName(b, lines[i]);
      consumed.add(i);
      break;
    }
  }

  // Company fallback: first remaining unconsumed line.
  if (b.company.isEmpty) {
    for (var i = 0; i < lines.length; i++) {
      if (consumed.contains(i)) continue;
      b.company = lines[i];
      break;
    }
  }

  return b.build();
}
