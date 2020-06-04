class DiscussionConverter
  class InvalidDiscussionException < StandardError
  end

  def self.convert(forum_discussion, raise_on_invalid: true)
    raise InvalidDiscussionException if forum_discussion.Closed == 1 || forum_discussion.rating == ForumDiscussion::RATING_REPORT

    discussion = Discussion.new(
      poster: forum_discussion.original_poster,
      created_at: forum_discussion.created,
      script: forum_discussion.script,
      rating: forum_discussion.rating
    )

    raise InvalidDiscussionException if raise_on_invalid && !discussion.valid?

    comment = discussion.comments.build(
      poster: forum_discussion.original_poster,
      text: forum_discussion.name + "\n\n" + forum_discussion.Body,
      text_markup: get_markup(forum_discussion),
      created_at: forum_discussion.created,
      edited_at: forum_discussion.DateUpdated,
      first_comment: true,
    )

    raise InvalidDiscussionException if raise_on_invalid && !comment.valid?

    forum_discussion.forum_comments.each do |forum_comment|
      discussion.comments.build(
        poster: forum_comment.poster,
        text: forum_comment.Body,
        text_markup: get_markup(forum_comment),
        created_at: forum_comment.DateInserted,
        edited_at: forum_comment.DateUpdated
      )
      raise InvalidDiscussionException if raise_on_invalid && !comment.valid?
    end

    discussion.assign_stats

    discussion
  end

  def self.get_markup(discussion_or_comment)
    format = discussion_or_comment.Format.downcase
    return format if %w[html markdown].include?(format)

    'markdown'
  end
end