class Article < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 15 }

  belongs_to :author, class_name: 'User', foreign_key: :user_id
  belongs_to :approver, class_name: 'User', foreign_key: :approver_id, optional: true
  has_and_belongs_to_many :tags

  before_save :render_markdown

  scope :ordered, -> { order(id: :desc) }
  scope :viewable_by, (lambda do |user|
    if user&.permission? :reviewer
      all
    elsif user.present?
      where.not(approver: nil).or(where(author: user))
    else
      where.not(approver: nil)
    end
  end)

  def approved?
    approver.present?
  end

  private

  def render_markdown
    renderer = Redcarpet::Render::XHTML.new with_toc_data: true,
                                            prettify: true,
                                            link_attribute: true
    markdown = Redcarpet::Markdown.new renderer,
                                       tables: true,
                                       fenced_code_blocks: true,
                                       autolink: true,
                                       strikethrough: true,
                                       lax_spacing: true,
                                       space_after_header: true,
                                       superscript: true,
                                       underline: true,
                                       highlight: true,
                                       quote: true,
                                       footnotes: true
    rendered_fragment = Loofah.fragment markdown.render(body)
    self.rendered = rendered_fragment.scrub!(:strip).to_s
    self.summary = rendered_fragment.to_text.truncate(256).split("\n").join(' ')
  end
end