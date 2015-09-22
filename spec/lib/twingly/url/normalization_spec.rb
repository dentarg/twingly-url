require "spec_helper"

describe Twingly::URL::Normalizer do
  let (:normalizer) { Twingly::URL::Normalizer }

  describe ".normalize" do
    it "accepts a String" do
      expect { normalizer.normalize("") }.not_to raise_error
    end

    it "accepts an Array" do
      expect { normalizer.normalize([]) }.not_to raise_error
    end

    it "does not create URLs for normal words" do
      url = "This is, just, some words. Yay!"
      expect(normalizer.normalize(url)).to eq([])
    end

    it "invokes .normalize_url for each url in an Array" do
      urls = %w(http://blog.twingly.com/ http://twingly.com/)

      expect(normalizer).to receive(:normalize_url).with(urls.first)
      expect(normalizer).to receive(:normalize_url).with(urls.last)

      normalizer.normalize(urls)
    end

    it "invokes .normalize_url for each url in a String" do
      urls = %w(http://blog.twingly.com/ http://twingly.com/)

      expect(normalizer).to receive(:normalize_url).with(urls.first)
      expect(normalizer).to receive(:normalize_url).with(urls.last)

      normalizer.normalize(urls.join(" "))
    end
  end

  describe ".extract_urls" do
    let(:urls) { %w(http://blog.twingly.com/ http://twingly.com/) }

    it "detects two urls in a String" do
      response = normalizer.extract_urls(urls.join(" "))

      expect(response.size).to eq(urls.size)
    end

    it "detects two urls in an Array" do
      response = normalizer.extract_urls(urls)

      expect(response.size).to eq(urls.size)
    end

    it "always returns an Array" do
      response = normalizer.extract_urls(nil)

      expect(response).to be_instance_of(Array)
    end
  end

  describe ".normalize_url" do
    it "adds www if host is missing a subdomain" do
      url = "http://twingly.com/"

      expect(normalizer.normalize_url(url)).to eq("http://www.twingly.com/")
    end

    it "does not add www if the host has a subdomain" do
      url = "http://blog.twingly.com/"

      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "does not remove www if the host has a subdomain" do
      url = "http://www.blog.twingly.com/"

      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "keeps www if the host already has it" do
      url = "http://www.twingly.com/"

      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "adds a trailing slash if missing in origin" do
      url = "http://www.twingly.com"
      expected = "http://www.twingly.com/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "ensures single trailing slash in origin" do
      url = "http://www.twingly.com//"
      expected = "http://www.twingly.com/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "removes trailing slash from path" do
      url = "http://www.twingly.com/blog-data/"
      expected = "http://www.twingly.com/blog-data"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "is able to normalize a url with double slash in path" do
      url = "www.twingly.com/path//"
      expected = "http://www.twingly.com/path"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "is able to normalize a url without protocol" do
      url = "www.twingly.com/"
      expected = "http://www.twingly.com/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "does not return broken URLs" do
      url = "http://www.twingly."

      expect(normalizer.normalize_url(url)).to be_nil
    end

    it "oddly enough, does not alter URLs with consecutive dots" do
      url = "http://www..twingly..com/"

      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "does not add www. to blogspot URLs" do
      url = "http://jlchen1026.blogspot.com/"

      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "removes www. from blogspot URLs" do
      url = "http://www.jlchen1026.blogspot.com/"
      expected = "http://jlchen1026.blogspot.com/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "rewrites blogspot TLDs to .com" do
      url = "http://WWW.jlchen1026.blogspot.CO.UK/"
      expected = "http://jlchen1026.blogspot.com/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "downcases the protocol" do
      url = "HTTPS://www.twingly.com/"
      expected = "https://www.twingly.com/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "downcases the domain" do
      url = "http://WWW.TWINGLY.COM/"
      expected = "http://www.twingly.com/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "does not downcase the path" do
      url = "http://www.twingly.com/PaTH"

      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "does not downcase fragment" do
      url = "http://www.twingly.com/#FRAGment"

      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "handles URL with ] in it" do
      url = "http://www.iwaseki.co.jp/cgi/yybbs/yybbs.cgi/%DEuropean]buy"
      expect { normalizer.normalize_url(url) }.not_to raise_error
    end

    it "handles URL with reference to another URL in it" do
      url = "http://news.google.com/news/url?sa=t&fd=R&usg=AFQjCNGc4A_sfGS6fMMqggiK_8h6yk2miw&url=http:%20%20%20//fansided.com/2013/08/02/nike-decides-to-drop-milwaukee-brewers-ryan-braun"
      expect { normalizer.normalize_url(url) }.not_to raise_error
    end

    it "handles URL with umlauts in host" do
      url = "http://www.åäö.se/"
      expected = "http://www.xn--4cab6c.se/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "handles URL with umlauts in path" do
      url = "http://www.aoo.se/öö"
      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "handles URL with punycoded SLD" do
      url = "http://www.xn--4cab6c.se/"

      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "handles URL with punycoded TLD" do
      url = "http://example.xn--p1ai/"
      expected = "http://www.example.xn--p1ai/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "converts to a punycoded URL" do
      url = "скраповыймир.рф"
      expected = "http://www.xn--80aesdcplhhhb0k.xn--p1ai/"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end

    it "does not blow up when there's only protocol in the text" do
      url = "http://"
      expect { normalizer.normalize_url(url) }.not_to raise_error
    end

    it "does not blow up when there's no URL in the text" do
      url = "Just some text"
      expect(normalizer.normalize_url(url)).to be_nil
    end

    it "handles bengali charachters in path" do
      url = "https://emani85.wordpress.com/2015/09/22/ইসরায়েল-থেকে-ড্রোন-কিনছে"
      expected = "https://emani85.wordpress.com/2015/09/22/%e0%a6%87%e0%a6%b8%e0%a6%b0%e0%a6%be%e0%a7%9f%e0%a7%87%e0%a6%b2-%e0%a6%a5%e0%a7%87%e0%a6%95%e0%a7%87-%e0%a6%a1%e0%a7%8d%e0%a6%b0%e0%a7%8b%e0%a6%a8-%e0%a6%95%e0%a6%bf%e0%a6%a8%e0%a6%9b%e0%a7%87/"

      expect(normalizer.normalize_url(url)).to eq(url)
    end

    it "handles encoded bengali charachters in path" do
      url = "https://emani85.wordpress.com/2015/09/22/%e0%a6%87%e0%a6%b8%e0%a6%b0%e0%a6%be%e0%a7%9f%e0%a7%87%e0%a6%b2-%e0%a6%a5%e0%a7%87%e0%a6%95%e0%a7%87-%e0%a6%a1%e0%a7%8d%e0%a6%b0%e0%a7%8b%e0%a6%a8-%e0%a6%95%e0%a6%bf%e0%a6%a8%e0%a6%9b%e0%a7%87/"
      expected = "https://emani85.wordpress.com/2015/09/22/ইসরায়েল-থেকে-ড্রোন-কিনছে"

      expect(normalizer.normalize_url(url)).to eq(expected)
    end
  end
end
