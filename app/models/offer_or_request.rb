# NOTE: This class is an abstract base class for the
# offers_or_requests table. It should not be instantiated directly, use the
# Offer or Request models, or their descendents.
class OfferOrRequest < Base
  self.abstract_class = true
  self.table_name = "offers_and_requests"

  include PgSearch

  belongs_to :user
  belongs_to :pod

  pg_search_scope :en_text_search, against: {
    title: "A",
    description: "C",
  },
  ignoring: :accents,
  using: {
    tsearch: {
      dictionary: "english",
      any_word: true,
    }
  }

  pg_search_scope :fr_text_search, against: {
    title: "A",
    description: "C",
  },
  ignoring: :accents,
  using: {
    tsearch: {
      dictionary: "french",
      any_word: true,
    }
  }

  def self.visible_to_pod(pod)
    if Actual(pod)
      where(pod_id: [nil, pod.id])
    else
      where(pod_id: nil)
    end
  end

  def self.owned_by(user, pagination)
    Just(user)
    where(user_id: user.id).paginate(pagination)
  end

  def self.available_to(user, pagination)
    pod = Pod.home_pod_for_user(user)
    visible_to_pod(pod).includes(user: [:profile]).paginate(pagination)
  end

  def self.search_results(search_data, user, pagination)
    case I18n.locale
    when :fr
      fr_text_search(search_data[:search]).available_to(user, pagination)
    else
      en_text_search(search_data[:search]).available_to(user, pagination)
    end
  end

  def type_class
    self.class.name.demodulize.underscore
  end
end
