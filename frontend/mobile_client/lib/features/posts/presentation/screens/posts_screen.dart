import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/posts_provider.dart';
import '../widgets/post_card.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';

class PostsScreen extends ConsumerStatefulWidget {
  const PostsScreen({super.key});

  @override
  ConsumerState<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends ConsumerState<PostsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(postsProvider.notifier).loadPosts());
  }

  Future<void> _refresh() => ref.read(postsProvider.notifier).loadPosts();

  void _showCreatePost() {
    final ctrl = TextEditingController();
    // Local state for the modal to track selected images
    List<XFile> selectedImages = [];
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        // Use StatefulBuilder to update the UI within the bottom sheet
        // when images are added or removed.
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            Future<void> pickImages() async {
              final List<XFile> images = await picker.pickMultiImage();
              if (images.isNotEmpty) {
                setModalState(() {
                  selectedImages.addAll(images);
                });
              }
            }

            return Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Create Post',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: ctrl,
                    maxLines: 3,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: "What's on your mind?",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Image Preview List
                  if (selectedImages.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: selectedImages.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    // In web/mobile use File(path) or Image.network
                                    selectedImages[index].path,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    // Use errorBuilder for non-web file paths
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.image),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 12,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () => setModalState(
                                      () => selectedImages.removeAt(index)),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close,
                                        size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),

                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate,
                            color: Colors.blue),
                        onPressed: pickImages,
                      ),
                      const Text("Add Images",
                          style: TextStyle(color: Colors.blue)),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Consumer(builder: (ctx2, ref2, _) {
                    // Accessing the state to show a loading indicator on the button
                    final isLoading = ref2.watch(postsProvider).isLoading;

                    return ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final text = ctrl.text.trim();
                              if (text.isEmpty && selectedImages.isEmpty)
                                return;

                              // Calling the createPost method with selected images
                              final ok = await ref2
                                  .read(postsProvider.notifier)
                                  .createPost(
                                    text,
                                    images: selectedImages,
                                  );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                    content: Text(ok
                                        ? 'Post created!'
                                        : 'Failed to post')));
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Post'),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postsProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePost,
        child: const Icon(Icons.add),
      ),
      body: Builder(
        builder: (_) {
          if (state.isLoading && state.posts.isEmpty) {
            return const AppLoadingWidget(message: 'Loading posts...');
          }
          if (state.error != null && state.posts.isEmpty) {
            return AppErrorWidget(message: state.error!, onRetry: _refresh);
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: state.posts.isEmpty
                ? const Center(
                    child: Text('No posts yet. Be the first to post!'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: state.posts.length,
                    itemBuilder: (_, i) => PostCard(post: state.posts[i]),
                  ),
          );
        },
      ),
    );
  }
}
