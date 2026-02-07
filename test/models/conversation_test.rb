require "test_helper"

class QueryLens::ConversationTest < ActiveSupport::TestCase
  setup do
    create_query_lens_tables!
    QueryLens::Conversation.delete_all
  end

  test "valid conversation saves successfully" do
    convo = QueryLens::Conversation.new(
      title: "How many users?",
      messages: [{ "role" => "user", "content" => "How many users?" }]
    )
    assert convo.save
    assert convo.persisted?
  end

  test "requires title" do
    convo = QueryLens::Conversation.new(
      title: nil,
      messages: [{ "role" => "user", "content" => "test" }]
    )
    assert_not convo.valid?
    assert_includes convo.errors[:title], "can't be blank"
  end

  test "requires messages" do
    convo = QueryLens::Conversation.new(title: "Test", messages: [])
    assert_not convo.valid?
    assert_includes convo.errors[:messages], "can't be blank"
  end

  test "messages are serialized as JSON" do
    msgs = [
      { "role" => "user", "content" => "How many users?" },
      { "role" => "assistant", "content" => "SELECT COUNT(*) FROM users" }
    ]
    convo = QueryLens::Conversation.create!(title: "Test", messages: msgs)
    convo.reload

    assert_equal 2, convo.messages.length
    assert_equal "user", convo.messages[0]["role"]
    assert_equal "assistant", convo.messages[1]["role"]
  end

  test "default scope orders by updated_at desc" do
    old = QueryLens::Conversation.create!(title: "Old", messages: [{ "role" => "user", "content" => "old" }])
    old.update_column(:updated_at, 2.hours.ago)

    new_convo = QueryLens::Conversation.create!(title: "New", messages: [{ "role" => "user", "content" => "new" }])

    conversations = QueryLens::Conversation.all.to_a
    assert_equal [new_convo, old], conversations
  end

  test "title_from_message truncates to 80 chars" do
    short = "Hello"
    assert_equal "Hello", QueryLens::Conversation.title_from_message(short)

    long = "x" * 100
    result = QueryLens::Conversation.title_from_message(long)
    assert result.length <= 80
  end

  test "last_sql is optional" do
    convo = QueryLens::Conversation.new(
      title: "Test",
      messages: [{ "role" => "user", "content" => "test" }],
      last_sql: nil
    )
    assert convo.valid?
  end

  test "last_sql stores SQL text" do
    convo = QueryLens::Conversation.create!(
      title: "Test",
      messages: [{ "role" => "user", "content" => "test" }],
      last_sql: "SELECT COUNT(*) FROM users"
    )
    convo.reload
    assert_equal "SELECT COUNT(*) FROM users", convo.last_sql
  end
end
