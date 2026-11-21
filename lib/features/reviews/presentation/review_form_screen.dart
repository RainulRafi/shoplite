import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_input.dart';
import '../domain/review_validators.dart';
import 'my_reviews_provider.dart';

class ReviewFormScreen extends StatefulWidget {
  final int productId;
  final String productTitle;
  final String thumbnail;

  const ReviewFormScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.thumbnail,
  });

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _comment;
  int? _rating;
  String? _ratingError;
  bool _saving = false;
  String? _error;
  late final bool _editing;

  @override
  void initState() {
    super.initState();
    final existing = context.read<MyReviewsProvider>().forProduct(
      widget.productId,
    );
    _editing = existing != null;
    _rating = existing?.rating;
    _comment = TextEditingController(text: existing?.comment ?? '');
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;

    final formOk = _formKey.currentState!.validate();
    final ratingError = ReviewValidators.rating(_rating);
    setState(() => _ratingError = ratingError);
    if (!formOk || ratingError != null) return;

    final provider = context.read<MyReviewsProvider>();
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await provider.save(
      productId: widget.productId,
      productTitle: widget.productTitle,
      thumbnail: widget.thumbnail,
      rating: _rating,
      comment: _comment.text,
    );
    if (!mounted) return;

    switch (result) {
      case ReviewResult.saved:
        Navigator.of(context).pop(true);
      case ReviewResult.notSignedIn:
        Navigator.of(context).pop(false);
      case ReviewResult.invalid:
        setState(() {
          _saving = false;
          _error = 'Please check the highlighted fields.';
        });
      case ReviewResult.failed:
        setState(() {
          _saving = false;
          _error = 'Could not save your review. Please try again.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            tooltip: 'Close',
            icon: Icon(Icons.close, color: c.ink),
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          ),
          centerTitle: false,
          title: Text(
            _editing ? 'Edit review' : 'Write a review',
            style: TextStyle(
              color: c.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  widget.productTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, height: 1.3, color: c.muted),
                ),
                const SizedBox(height: 20),

                const FieldLabel('Your rating'),
                Row(
                  children: [
                    for (var star = 1; star <= 5; star++)
                      Semantics(
                        button: true,
                        selected: _rating == star,
                        label: '$star ${star == 1 ? 'star' : 'stars'}',
                        child: GestureDetector(
                          onTap: _saving
                              ? null
                              : () => setState(() {
                                  _rating = star;
                                  _ratingError = null;
                                }),
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              (_rating ?? 0) >= star
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 32,
                              color: c.highlight,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_ratingError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _ratingError!,
                      style: TextStyle(fontSize: 13, color: c.danger),
                    ),
                  ),
                const SizedBox(height: 18),

                const FieldLabel('Your review'),
                TextFormField(
                  controller: _comment,
                  enabled: !_saving,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: ReviewValidators.maxComment,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: c.ink, fontSize: 15),
                  decoration: appInputDecoration(
                    context,
                    hint: 'What did you like or dislike?',
                  ),
                  validator: ReviewValidators.comment,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.danger,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.onAccent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  child: Text(_saving ? 'Saving...' : 'Save review'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your review is saved on this phone only.',
                  style: TextStyle(fontSize: 13, color: c.faint),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
