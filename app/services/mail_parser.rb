class MailParser

  def initialize(mails)
    mails.each do |mail|
      data = parse_body(mail[:body])
      mail.merge!(data: data)
    end
  end

  def parse_body(body)
    html_doc = Nokogiri::HTML(body)
    html_doc.css("p").text.split(/[\r\n]+/)
  end

end
