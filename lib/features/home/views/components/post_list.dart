import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/core/widgets/common_alert.dart';
import 'package:gplx/features/home/controllers/mixin_home.dart';

class PostList extends ConsumerWidget with MixinHome {
  const PostList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log('Build list of posts');
    final postsAsyncValue = postsAsyncValueState(ref);

    return postsAsyncValue.when(
      data: (posts) => Column(
        children: posts
            .map(
              (post) => ListTile(
                title: Text(post.title ?? ''),
                subtitle: Text(post.body ?? ''),
              ),
            )
            .toList(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => CommonAlert(
        exception: err,
        onRetry: () => fetchPost(ref),
      ),
    );
  }
}
