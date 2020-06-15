

## for devtools
library(git2r);library(digest)
#require(devtools)
#install_github("hadley/devtools")
library(devtools)
#install_github("geoffjentry/twitteR")

## data manipultion
library(dplyr);library(stringr)

# loading the libraries
## Linked to importing tweets
library(rjson);library(httr);library(twitteR);library(rtweet)

## Linked to generating a wordcloud
library(tm);library(NLP);library(RCurl);library(RJSONIO)
library(stringr);library(wordcloud);library(wordcloud2); 

#To create Shiny environment
library(shinythemes)

## Linked to sentiment analysis
library(syuzhet)
library("twitteR")
library("ROAuth")
library(base64enc)
library(httpuv)


searchThis = function(search_string, n, lang='en', retryonratelimit = FALSE)
{
  twitter_token <- create_token(
    app = '',
    consumer_key <- "",
    consumer_secret <- "",
    access_token <- "",
    access_secret <- "",
    set_renv = F
  )
  
  
  
  #df.tweets<-search_tweets(search_string,n = 150,lang="english")
  df.tweets <- search_tweets(search_string, n = n, include_rts = FALSE, lang = lang, token = twitter_token, retryonratelimit = retryonratelimit)
  # print(paste0("Total Tweets downloaded for - ",tag,": ",length(tweet.df$text)))
  #print(paste0("Total Unique Texts downloaded for - ",tag,": ",length(unique(tweet.df$text))))
}



cleanTweets = function(df.tweets){
  # list to dataframe
  #df.tweets <- twListToDF(df.tweets)
  
  # Removes RT
  df.tweets$text_clean = gsub("(RT|via)((?:\\b\\W*@\\w+)+)", "", df.tweets$text)
  
  #Remove non-ASCII characters
  Encoding(df.tweets$text_clean) = "latin1"
  iconv(df.tweets$text_clean, "latin1", "ASCII", sub = "")
  
  # Removes @<twitter handle>
  df.tweets$text_clean = gsub("@\\w+", "", df.tweets$text_clean)
  # Removes punctuations
  df.tweets$text_clean = gsub("[[:punct:]]", "", df.tweets$text_clean)
  # Removes numbers
  df.tweets$text_clean = gsub("[[:digit:]]", "", df.tweets$text_clean)
  # Removes html links
  df.tweets$text_clean = gsub("http\\w+", "", df.tweets$text_clean)
  # Removes unnecessary spaces
  df.tweets$text_clean = gsub("[ \t]{2,}", "", df.tweets$text_clean)
  df.tweets$text_clean = gsub("^\\s+|\\s+$", "", df.tweets$text_clean)
  # Fix for error related to formatting 'utf8towcs'"
  df.tweets$text_clean <- str_replace_all(df.tweets$text_clean,"[^[:graph:]]", " ")
  return(df.tweets)
}



# Generate Term Document Matrix using stopword list from tm pacakge
tdm.tmStopWord = function(clean.tweets.dataframe){
  # Creates a text corpus from the plain text document for every tweet
  text_corpus = Corpus(VectorSource(clean.tweets.dataframe$text_clean))
  # Text_corpus is a collection of tweets where every tweet is a document
  
  # creating a Term Document Matrix 
  tdm = TermDocumentMatrix(
    # the text corpus created from the text_clean object
    text_corpus,
    # defining the stopwords to be removed before creating a term document matrix
    control = list(
      removePunctuation = TRUE,
      stopwords("en"),
      removeNumbers = TRUE,
      tolower = TRUE)
  )
  
  return(tdm)
}

# Generate Term Document Matrix using TF-IDF
tdm.TFIDF = function(clean.tweets.dataframe){
  
  text_corpus = Corpus(VectorSource(clean.tweets.dataframe$text_clean))
  
  # Text_corpus is a collection of tweets where every tweet is a document
  tdm <- DocumentTermMatrix(text_corpus, control = list(weighting = weightTfIdf))
  
  return(tdm)
}

# Generate Term Document Matrix without removing stopwords
tdm.tm = function(clean.tweets.dataframe){
  
  text_corpus = Corpus(VectorSource(clean.tweets.dataframe$text_clean))
  tdm = TermDocumentMatrix(text_corpus,control = list(removePunctuation = TRUE,
                                                      removeNumbers = TRUE,
                                                      tolower = TRUE))
  
  return(tdm)
}

getSentiments.TF_IDF.nrc = function(tdm.tfidf){
  
  m <- as.matrix(tdm.tfidf)
  
  word_tfidf <- sort(colSums(m), decreasing = TRUE)
  dm <- data.frame(word = names(word_tfidf), tfidf = word_tfidf)
  dm.subset <- dm[dm$tfidf>=quantile(dm$tfidf,0.25),]
  nrc.lex <- get_nrc_sentiment(as.character(dm.subset$word))
  
}

generateWordCloud.positive.tmStopWords = function(tdm.tm.stopword){
  
  
  # converting term document matrix to matrix
  m = as.matrix(tdm.tm.stopword)
  
  # get word counts in decreasing order
  word_freqs = sort(rowSums(m), decreasing = TRUE)
  
  # create a data frame with words and their frequencies
  dm = data.frame(word = names(word_freqs), freq = word_freqs)
  
  nrc.lexicons = get_nrc_sentiment(as.character(dm$word))
  tweets.positive = dm[nrc.lexicons$positive>0,]
  
}

generateWordCloud.negative.tmStopWords = function(tdm.tm.stopword){
  
  # converting term document matrix to matrix
  m = as.matrix(tdm.tm.stopword)
  
  # get word counts in decreasing order
  word_freqs = sort(rowSums(m), decreasing = TRUE)
  
  # create a data frame with words and their frequencies
  dm = data.frame(word = names(word_freqs), freq = word_freqs)
  
  nrc.lexicons = get_nrc_sentiment(as.character(dm$word))
  
  tweets.negative = dm[nrc.lexicons$negative>0,]
}

generateWordCloud.positive.TF_IDF = function(tdm.tfidf, tdm.tm.nostop){
  
  # converting term document matrix to matrix
  m <- as.matrix(tdm.tfidf)
  
  word_tfidf <- sort(colSums(m), decreasing = TRUE)
  # create a data frame with words and their frequencies
  dm <- data.frame(word = names(word_tfidf), tfidf = word_tfidf)
  #plot(dm$freq,type = "l")
  dm.subset <- dm[dm$tfidf>=quantile(dm$tfidf,0.25),]
  
  ## creating term frequency dataframe
  m.word.freq <- as.matrix(tdm.tm.nostop)
  word_freqs.word.freq <- sort(colSums(m), decreasing = TRUE)
  dm.word.freq <- data.frame(word = names(word_freqs.word.freq), freq = word_freqs.word.freq)
  
  ## subsetting the tdm 
  dm.word.freq.new <- dm.word.freq[dm.word.freq$word %in% dm.subset$word,]
  
  nrc.lexicons <- get_nrc_sentiment(as.character(dm.word.freq.new$word))
  tweets.positive <- dm.word.freq.new[nrc.lexicons$positive>0,]
}

generateWordCloud.negative.TF_IDF = function(tdm.tfidf, tdm.tm.nostop){
  # converting term document matrix to matrix
  m <- as.matrix(tdm.tfidf)
  
  word_tfidf <- sort(colSums(m), decreasing = TRUE)
  # create a data frame with words and their frequencies
  dm <- data.frame(word = names(word_tfidf), tfidf = word_tfidf)
  #plot(dm$freq,type = "l")
  dm.subset <- dm[dm$tfidf>=quantile(dm$tfidf,0.25),]
  
  ## creating term frequency dataframe
  m.word.freq <- as.matrix(tdm.tm.nostop)
  word_freqs.word.freq <- sort(colSums(m), decreasing = TRUE)
  dm.word.freq <- data.frame(word = names(word_freqs.word.freq), freq = word_freqs.word.freq)
  
  ## subsetting the tdm 
  dm.word.freq.new <- dm.word.freq[dm.word.freq$word %in% dm.subset$word,]
  
  nrc.lexicons <- get_nrc_sentiment(as.character(dm.word.freq.new$word))
  tweets.negative <- dm.word.freq.new[nrc.lexicons$negative>0,]
}



