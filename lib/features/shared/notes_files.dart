import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';

/// Notes + Files sections for a record, embeddable inside a detail ListView.
///
/// Mirrors the backend `notes` and `files` routers. Notes are first-class
/// (title, body, pin), separate from the freeform `notes` string on the
/// record itself.
class RecordNotesFiles extends StatelessWidget {
  const RecordNotesFiles({
    super.key,
    required this.relatedType,
    required this.relatedId,
    required this.relatedName,
  });

  final RecordType relatedType;
  final String relatedId;
  final String relatedName;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final notes = store.notesForRecord(relatedType, relatedId);
    final files = store.attachmentsForRecord(relatedType, relatedId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Notes',
          actionLabel: '+ Add',
          onAction: () => showNoteSheet(
            context,
            relatedType: relatedType,
            relatedId: relatedId,
            relatedName: relatedName,
          ),
        ),
        if (notes.isEmpty)
          const _InlineEmpty(
            icon: Icons.sticky_note_2_outlined,
            text: 'No notes yet — capture a thought or meeting takeaway.',
          )
        else
          for (final note in notes)
            _NoteCard(note: note, relatedName: relatedName),
        SectionHeader(
          title: 'Files',
          actionLabel: '+ Attach',
          onAction: () => showAttachSheet(
            context,
            relatedType: relatedType,
            relatedId: relatedId,
          ),
        ),
        if (files.isEmpty)
          const _InlineEmpty(
            icon: Icons.attach_file,
            text: 'No files attached. Add a photo, document, or link.',
          )
        else
          for (final file in files) _FileCard(attachment: file),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  const _InlineEmpty({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.relatedName});

  final Note note;
  final String relatedName;

  @override
  Widget build(BuildContext context) {
    final store = context.read<CrmStore>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (note.title.isNotEmpty)
                      Text(
                        note.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    if (note.title.isNotEmpty) const SizedBox(height: 3),
                    Text(
                      note.body,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (note.pinned) ...[
                          const Icon(Icons.push_pin,
                              size: 12, color: AppColors.brandAccent),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            '${Formatters.relative(note.updatedAt)}'
                            '${note.authorName.isEmpty ? '' : ' · ${note.authorName}'}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppColors.textTertiary),
                onSelected: (value) {
                  switch (value) {
                    case 'pin':
                      store.togglePinNote(note);
                    case 'edit':
                      showNoteSheet(
                        context,
                        relatedType: note.relatedType,
                        relatedId: note.relatedId,
                        relatedName: relatedName,
                        existing: note,
                      );
                    case 'delete':
                      store.deleteNote(note.id);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Text(note.pinned ? 'Unpin' : 'Pin'),
                  ),
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.attachment});

  final Attachment attachment;

  @override
  Widget build(BuildContext context) {
    final store = context.read<CrmStore>();
    final kind = attachment.kind;
    final subtitle = [
      if (attachment.sizeLabel.isNotEmpty) attachment.sizeLabel,
      if (attachment.addedByName.isNotEmpty) attachment.addedByName,
      Formatters.relative(attachment.createdAt),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kind.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(kind.icon, size: 20, color: kind.color),
          ),
          title: Text(
            attachment.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: AppColors.textTertiary),
            onPressed: () => store.deleteAttachment(attachment.id),
          ),
          onTap: kind == AttachmentKind.link && attachment.url.isNotEmpty
              ? () => _showLink(context, attachment)
              : null,
        ),
      ),
    );
  }

  void _showLink(BuildContext context, Attachment a) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(a.name),
        content: SelectableText(a.url),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Add or edit a note in a bottom sheet.
Future<void> showNoteSheet(
  BuildContext context, {
  required RecordType relatedType,
  required String relatedId,
  required String relatedName,
  Note? existing,
}) {
  final titleController = TextEditingController(text: existing?.title ?? '');
  final bodyController = TextEditingController(text: existing?.body ?? '');

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              existing == null ? 'New note · $relatedName' : 'Edit note',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Title (optional)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: bodyController,
              maxLines: 5,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Write a note…'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final body = bodyController.text.trim();
                  final title = titleController.text.trim();
                  if (body.isEmpty && title.isEmpty) return;
                  final store = sheetContext.read<CrmStore>();
                  if (existing == null) {
                    final now = DateTime.now();
                    store.addNote(Note(
                      id: store.newId(),
                      title: title,
                      body: body,
                      relatedType: relatedType,
                      relatedId: relatedId,
                      authorName: store.currentUserName,
                      createdAt: now,
                      updatedAt: now,
                    ));
                  } else {
                    store.updateNote(existing.copyWith(
                      title: title,
                      body: body,
                    ));
                  }
                  Navigator.of(sheetContext).pop();
                },
                child: Text(existing == null ? 'Save note' : 'Update note'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Attach a file or link to a record.
Future<void> showAttachSheet(
  BuildContext context, {
  required RecordType relatedType,
  required String relatedId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      void attach(Attachment attachment) {
        sheetContext.read<CrmStore>().addAttachment(attachment);
        Navigator.of(sheetContext).pop();
      }

      Attachment build(String name, AttachmentKind kind, {String url = ''}) {
        final store = sheetContext.read<CrmStore>();
        return Attachment(
          id: store.newId(),
          name: name,
          kind: kind,
          url: url,
          relatedType: relatedType,
          relatedId: relatedId,
          addedByName: store.currentUserName,
          createdAt: DateTime.now(),
        );
      }

      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Attach to record',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
            ),
            _AttachTile(
              icon: Icons.photo_camera_outlined,
              label: 'Take photo',
              subtitle: 'Capture a whiteboard, receipt, or badge',
              onTap: () => attach(
                build('Photo ${Formatters.fileStamp(DateTime.now())}.jpg',
                    AttachmentKind.image),
              ),
            ),
            _AttachTile(
              icon: Icons.image_outlined,
              label: 'Photo library',
              subtitle: 'Attach an existing image',
              onTap: () => attach(
                build('Image ${Formatters.fileStamp(DateTime.now())}.png',
                    AttachmentKind.image),
              ),
            ),
            _AttachTile(
              icon: Icons.description_outlined,
              label: 'Document',
              subtitle: 'PDF, Word, spreadsheet, or slides',
              onTap: () => attach(
                build('Document ${Formatters.fileStamp(DateTime.now())}.pdf',
                    AttachmentKind.pdf),
              ),
            ),
            _AttachTile(
              icon: Icons.link,
              label: 'Add link',
              subtitle: 'Attach a URL',
              onTap: () async {
                final link = await _promptLink(sheetContext);
                if (link == null) return;
                attach(build(
                  link.name.isEmpty ? link.url : link.name,
                  AttachmentKind.link,
                  url: link.url,
                ));
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
    },
  );
}

class _AttachTile extends StatelessWidget {
  const _AttachTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.brand),
      ),
      title: Text(label,
          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
    );
  }
}

class _LinkInput {
  const _LinkInput(this.url, this.name);
  final String url;
  final String name;
}

Future<_LinkInput?> _promptLink(BuildContext context) {
  final urlController = TextEditingController();
  final nameController = TextEditingController();
  return showDialog<_LinkInput>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add link'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'https://…'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Label (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final url = urlController.text.trim();
            if (url.isEmpty) return;
            Navigator.of(dialogContext)
                .pop(_LinkInput(url, nameController.text.trim()));
          },
          child: const Text('Add'),
        ),
      ],
    ),
  );
}
