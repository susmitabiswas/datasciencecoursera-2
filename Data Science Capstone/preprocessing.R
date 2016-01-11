#Load Packages
library(tm)
library(RWeka)

#Load Data
dir = 'input/en_US/'
train_blogs = readLines(paste0(dir,"en_US.blogs.txt"))
train_twitter = readLines(paste0(dir,"en_US.twitter.txt"))
con = file(paste0(dir,"en_US.news.txt"), open="rb")
train_news = readLines(con, encoding="UTF-8")
close(con)

#Sample data size due to memory issues
set.seed(100)
train_blogs = sample(train_blogs, 200000)
train_news = sample(train_news, 200000)
train_twitter = sample(train_twitter, 200000)

#Create a corpus from dataset
create_corpus = function(dm){
  corpus = Corpus(VectorSource(dm))
  corpus = tm_map(corpus, removeNumbers) # remove numbers
  corpus = tm_map(corpus, stripWhitespace) # remove whitespaces
  corpus = tm_map(corpus, tolower) #lowercase all contents
  corpus = tm_map(corpus, removePunctuation) # remove punctuation
  corpus = tm_map(corpus, removeWords, c("fuck", "bitch", "ass", "cunt", "pussy", "asshole", "douche")) #remove some swears
  corpus = tm_map(corpus, PlainTextDocument) #convert to plaintextdocument
  
  return(corpus)
}

#Setup corpus from training data
train_words = c(train_blogs, train_news, train_twitter)
train_corpus = create_corpus(train_words)

#Create 1gram
ngram1 = DocumentTermMatrix(train_corpus)
ngram1 = removeSparseTerms(ngram1, 0.999)
ngram1 = as.data.frame(as.matrix(ngram1))


#Create 2-grams
create_n2 = function(corpus){
  TwogramTokenizer = function(x) NGramTokenizer(x, Weka_control(min = 2, max = 2))
  ngram2 = TermDocumentMatrix(corpus, control = list(tokenize = TwogramTokenizer))
  ngram2 = removeSparseTerms(ngram2, 0.999)
  ngram2 = as.data.frame(as.matrix(ngram2))
  
  return(ngram2)
}

ngram2 = create_n2(train_corpus)

#Create 3-grams
TrigramTokenizer = function(x) NGramTokenizer(x, Weka_control(min = 3, max = 3))
ngram3 = TermDocumentMatrix(train_corpus, control = list(tokenize = TrigramTokenizer))
ngram3 = removeSparseTerms(ngram3, 0.999)
ngram3 = as.data.frame(as.matrix(ngram3))



#Process raw ngrams
ngram1_total = colSums(ngram1)
ngram1_raw = as.numeric(ngram1_total[1:525])
ngram1_raw = data.frame(names(ngram1),ngram1_raw)
names(ngram1_raw) = c("words", "total")
ngram1_raw$start = substr(ngram1_raw$words, 1,1)

#Preceding word, after
ngram2_total = rowSums(ngram2)
ngram2_raw = as.numeric(ngram2_total[1:nrow(ngram2)])
ngram2_raw = data.frame(names(ngram2_total),ngram2_raw)
names(ngram2_raw) = c("words", "total")
ngram2_raw$word1 = "dummy"
ngram2_raw$word2 = "dummy"
for(i in 1:nrow(ngram2_raw)){
  split_words = unlist(strsplit(as.character(ngram2_raw$words[i]), " "))
  ngram2_raw$word1[i] = split_words[1]
  ngram2_raw$word2[i] = split_words[2]
}

#Preceding phrase, after
ngram3_total = rowSums(ngram3)
ngram3_raw = as.numeric(ngram3_total[1:nrow(ngram3)])
ngram3_raw = data.frame(names(ngram3_total),ngram3_raw)
names(ngram3_raw) = c("words", "total")
ngram3_raw$phrase = "dummy"
ngram3_raw$word3 = "dummy"
for(i in 1:nrow(ngram3_raw)){
  split_words = unlist(strsplit(as.character(ngram3_raw$words[i]), " "))
  ngram3_raw$phrase[i] = paste(split_words[1],split_words[2], sep=" ")
  ngram3_raw$word3[i] = split_words[3]
}