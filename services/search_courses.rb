# frozen_string_literal: true

# Search courses from Coursera, Udacity, and YouTube using external API rather
# than retrieving from our own databse currently
class SearchCourses
  extend Dry::Monads::Either::Mixin
  extend Dry::Container::Mixin

  register :parse_keyword, lambda { |params|
    keyword = params[:search_keyword]
    keyword = keyword.tr('+', ' ') if keyword.include? '+'
    if keyword
      results = SearchResults.new
      Right(keyword: keyword, results: results)
    else
      Left(Error.new(:no_keyword, 'Keyword not given'))
    end
  }

  register :search_coursera, lambda { |input|
    begin
      # results_coursera =
      # Coursera::CourseraCourses.find.search_courses(:all, input[:keyword])
      results_coursera = Course.where(source: 'Coursera').where(
        Sequel.join([:title, :introduction]).ilike("%#{input[:keyword]}%")
      ).all

      refined_results_coursera = SearchResultsSingleSource.new(
        results_coursera.count,
        results_coursera.map do |course|
          search_results_course = SearchResultsCourse.new(
            course.id,
            course.title,
            course.introduction,
            course.link,
            course.photo
          )
          search_results_course
        end
      )

      input[:results].coursera = refined_results_coursera
      Right(input)
    rescue
      Left(
        Error.new(
          :internal_server_error,
          'Exception during search in Coursera'
        )
      )
    end
  }

  register :search_udacity, lambda { |input|
    begin
      # results_udacity =
      # Udacity::UdacityCourse.find.acquire_courses_by_keywords(input[:keyword])
      results_udacity = Course.where(source: 'Udacity').where(
        Sequel.join([:title, :introduction]).ilike("%#{input[:keyword]}%")
      ).all

      refined_results_udacity = SearchResultsSingleSource.new(
        results_udacity.count,
        results_udacity.map do |course|
          search_results_course = SearchResultsCourse.new(
            course.id,
            course.title,
            course.introduction,
            course.link,
            course.photo
          )
          search_results_course
        end
      )

      input[:results].udacity = refined_results_udacity
      Right(input)
    rescue
      Left(
        Error.new(
          :internal_server_error,
          'Exception during search in Udacity'
        )
      )
    end
  }

  register :search_youtube, lambda { |input|
    begin
      results_youtube =
        YouTube::YouTubePlaylist.find(keyword: input[:keyword]).results

      refined_results_youtube = SearchResultsSingleSource.new(
        results_youtube.count,
        results_youtube.map do |course|
          search_results_course = SearchResultsCourse.new(
            -1, # Since we still used external API of YouTube here, so no id
            course['title'],
            course['description'],
            course['url'],
            course['image']
          )
          search_results_course
        end
      )

      input[:results].youtube = refined_results_youtube
      Right(input[:results])
    rescue
      Left(
        Error.new(
          :internal_server_error,
          'Exception during search in YouTube'
        )
      )
    end
  }

  def self.call(params)
    Dry.Transaction(container: self) do
      step :parse_keyword
      step :search_coursera
      step :search_udacity
      step :search_youtube
    end.call(params)
  end
end
