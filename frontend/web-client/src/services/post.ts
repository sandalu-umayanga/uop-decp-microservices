import api from "./api";
import type { Post, PostRequest } from "../types";

export const postService = {
  getAll: () => api.get<Post[]>("/api/posts"),

  create: (data: PostRequest) => api.post<Post>("/api/posts", data),

  uploadMedia: (file: File) => {
    const form = new FormData();
    form.append("file", file);
    return api.post<{ url: string }>("/api/posts/media", form, {
      headers: { "Content-Type": "multipart/form-data" },
    });
  },

  like: (postId: string, userId: string) =>
    api.post<Post>(`/api/posts/${postId}/like`, { userId }),

  addComment: (
    postId: string,
    comment: { userId: string; username: string; text: string },
  ) => api.post<Post>(`/api/posts/${postId}/comment`, comment),
};
