import 'dart:developer';

import 'package:gh247_user/core/widgets/common_alert.dart';
import 'package:gh247_user/features/home/controllers/mixin_home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
