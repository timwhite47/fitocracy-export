require 'capybara'
require 'capybara/poltergeist'
require 'capybara/dsl'
require 'pry'

class FitocracyScraper
  include Capybara::DSL

  def initialize(username, password)
    @username = username
    @password = password

    Capybara.current_driver    = :poltergeist
    Capybara.app_host          = 'http://www.fitocracy.com'
    Capybara.default_wait_time = 20
  end

  def log_in
    print 'Logging in... '
    visit '/'

    within 'form#login-modal-form', visible: false do
      find(:xpath, '//*[@id="login-modal-form"]/div[2]/div[1]/input', visible: false).set @username
      find(:xpath, '//*[@id="login-modal-form"]/div[2]/div[2]/input', visible: false).set @password

      page.execute_script("$('form#login-modal-form').submit()")
    end

    wait_for_home_page_load
    puts 'success!'
  end

  def export_all
    visit_performance_page

    exercise_list.each do |exercise|
      export_exercise(exercise)
    end
  end

  private
  def export_exercise(name)
    print "exporting #{name} ... "

    select name
    current_window_count = page.driver.browser.window_handles.length
    click_on 'CSV'
    wait_until { page.driver.browser.window_handles.length == current_window_count + 1 }

    within_window page.driver.browser.window_handles.last do
      csv      = current_csv
      filename = "#{Dir.home}/Dropbox/fitness/fitocracy/data#{name.gsub(' ', '_').gsub(/\W/, '').downcase}.csv"
      File.open(filename, 'w') { |file| file.write(csv) }

      puts "wrote #{csv.split("\n").length - 1} sets to #{filename}"
    end

  end

  def current_csv
    page.body.match(/<pre[^>]*>(.*)<\/pre>/m)[1]
  end

  def exercise_list
    all('select#history_activity_chooser option').to_a.map do |option|
      option.text
    end
  end

  def visit_performance_page
    visit "/profile/#{@username}/?performance"
    wait_for_performance_page_load
  end

  def wait_for_performance_page_load
    wait_until { page.has_css? 'select#history_activity_chooser' }
  end

  def wait_until
    Timeout.timeout(Capybara.default_wait_time) do
      loop { break if yield }
    end
  end

  def wait_for_home_page_load
    wait_until { page.has_css? '#home-feed-nav' }
  end

end
