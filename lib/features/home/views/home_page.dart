import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gplx/features/home/controllers/mixin_home.dart';
import 'package:gplx/features/home/views/components/post_list.dart';

class HomePage extends ConsumerWidget with MixinHome {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = counterState(ref);

    return Scaffold(
        appBar: AppBar(title: const Text('Posts')),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                  child: Text(
                '$counter',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              const PostList(),
            ],
          ),
        ),
        floatingActionButton: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              child: const Text('Refresh'),
              onPressed: () => refresh(ref),
            ),
            IconButton(
              onPressed: () => increment(ref),
              icon: const Icon(Icons.add),
            ),
            IconButton(
              onPressed: () => decrement(ref),
              icon: const Icon(Icons.remove),
            ),
          ],
        ));
  }
}
