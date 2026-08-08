import 'package:flutter_test/flutter_test.dart';
import 'package:ryse_crm/data/crm_store.dart';
import 'package:ryse_crm/data/models/models.dart';
import 'package:ryse_crm/features/leads/lead_scan.dart';
import 'package:ryse_crm/features/shell/quick_add.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Notes store', () {
    late CrmStore store;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = CrmStore();
      await store.load();
    });

    test('add, pin, edit, and delete a note on a record', () {
      final now = DateTime.now();
      final note = Note(
        id: store.newId(),
        title: 'Discovery',
        body: 'Budget confirmed for Q4.',
        relatedType: RecordType.opportunity,
        relatedId: 'opp-1',
        authorName: 'Rep',
        createdAt: now,
        updatedAt: now,
      );
      store.addNote(note);
      expect(store.notesForRecord(RecordType.opportunity, 'opp-1'), hasLength(1));
      // Adding a note also logs an activity on the record.
      expect(
        store.activitiesForRecord(RecordType.opportunity, 'opp-1'),
        isNotEmpty,
      );

      store.togglePinNote(note);
      expect(
        store.notesForRecord(RecordType.opportunity, 'opp-1').first.pinned,
        isTrue,
      );

      store.updateNote(note.copyWith(body: 'Budget confirmed for Q3.'));
      expect(
        store.notesForRecord(RecordType.opportunity, 'opp-1').first.body,
        contains('Q3'),
      );

      store.deleteNote(note.id);
      expect(store.notesForRecord(RecordType.opportunity, 'opp-1'), isEmpty);
    });

    test('pinned notes sort before unpinned', () {
      final now = DateTime.now();
      final a = Note(
        id: store.newId(),
        body: 'older',
        relatedType: RecordType.lead,
        relatedId: 'lead-1',
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      );
      final b = Note(
        id: store.newId(),
        body: 'newer',
        relatedType: RecordType.lead,
        relatedId: 'lead-1',
        createdAt: now,
        updatedAt: now,
      );
      store.addNote(a);
      store.addNote(b);
      store.togglePinNote(a); // pin the older one
      final notes = store.notesForRecord(RecordType.lead, 'lead-1');
      expect(notes.first.body, 'older');
    });
  });

  group('Attachments store', () {
    late CrmStore store;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = CrmStore();
      await store.load();
    });

    test('attach and remove a file on a record', () {
      final att = Attachment(
        id: store.newId(),
        name: 'proposal.pdf',
        kind: AttachmentKind.pdf,
        relatedType: RecordType.account,
        relatedId: 'acc-1',
        createdAt: DateTime.now(),
      );
      store.addAttachment(att);
      expect(store.attachmentsForRecord(RecordType.account, 'acc-1'),
          hasLength(1));
      store.deleteAttachment(att.id);
      expect(
          store.attachmentsForRecord(RecordType.account, 'acc-1'), isEmpty);
    });

    test('infers kind from filename', () {
      expect(AttachmentKind.fromFileName('deck.pptx'), AttachmentKind.slide);
      expect(AttachmentKind.fromFileName('sheet.xlsx'), AttachmentKind.sheet);
      expect(AttachmentKind.fromFileName('photo.HEIC'), AttachmentKind.image);
      expect(AttachmentKind.fromFileName('notes.txt'), AttachmentKind.other);
    });
  });

  group('Quick-add parser', () {
    final now = DateTime(2026, 8, 8, 10, 0); // Saturday

    test('parses a call with a company, relative day, and time', () {
      final r = parseQuickAdd('Call Acme Corp tomorrow 3pm about renewal',
          now: now);
      expect(r.type, TaskType.call);
      expect(r.dueDate.day, 9);
      expect(r.dueDate.hour, 15);
      expect(r.subject.toLowerCase(), contains('acme'));
      expect(r.subject.toLowerCase(), isNot(contains('tomorrow')));
    });

    test('detects an email task and high priority', () {
      final r = parseQuickAdd('Email the SOW to Globex asap', now: now);
      expect(r.type, TaskType.email);
      expect(r.priority, TaskPriority.high);
    });

    test('parses a weekday to the next occurrence', () {
      final r = parseQuickAdd('Meeting with the team on Monday 9am', now: now);
      expect(r.type, TaskType.meeting);
      expect(r.dueDate.weekday, DateTime.monday);
      expect(r.dueDate.isAfter(now), isTrue);
    });

    test('defaults to a to-do today at 9am when nothing matches', () {
      final r = parseQuickAdd('Prepare board deck', now: now);
      expect(r.type, TaskType.todo);
      expect(r.dueDate.day, 8);
      expect(r.dueDate.hour, 9);
    });
  });

  group('Lead scan — vCard/QR', () {
    test('parses a standard vCard payload', () {
      const payload = '''
BEGIN:VCARD
VERSION:3.0
FN:Jordan Lee
ORG:Acme Technologies
TITLE:VP of Sales
EMAIL;TYPE=WORK:jordan@acme.com
TEL;TYPE=CELL:+1-415-555-0199
URL:https://acme.com
ADR:;;500 Howard;San Francisco;CA;94105;USA
END:VCARD''';
      final p = parseVCard(payload);
      expect(p.firstName, 'Jordan');
      expect(p.lastName, 'Lee');
      expect(p.company, 'Acme Technologies');
      expect(p.title, 'VP of Sales');
      expect(p.email, 'jordan@acme.com');
      expect(p.phone, '+1-415-555-0199');
      expect(p.website, 'https://acme.com');
      expect(p.city, 'San Francisco');
      expect(p.country, 'USA');
    });

    test('parses a MECARD payload', () {
      const payload =
          'MECARD:N:Lee,Jordan;ORG:Acme;TEL:+14155550199;EMAIL:jl@acme.com;;';
      final p = parseVCard(payload);
      expect(p.firstName, 'Jordan');
      expect(p.lastName, 'Lee');
      expect(p.company, 'Acme');
      expect(p.email, 'jl@acme.com');
    });
  });

  group('Lead scan — business card OCR', () {
    test('extracts fields from typical card text', () {
      const card = '''
Jordan Lee
VP of Sales
Acme Technologies Inc.
jordan@acme.com
+1 (415) 555-0199
www.acme.com''';
      final p = parseBusinessCard(card);
      expect(p.firstName, 'Jordan');
      expect(p.lastName, 'Lee');
      expect(p.email, 'jordan@acme.com');
      expect(p.phone.replaceAll(RegExp(r'\D'), ''), contains('4155550199'));
      expect(p.title.toLowerCase(), contains('sales'));
      expect(p.company.toLowerCase(), contains('acme'));
      expect(p.website.toLowerCase(), contains('acme.com'));
    });
  });
}
