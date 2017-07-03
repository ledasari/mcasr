## Mismatched Crowdsourcing Automatic Speech Recognition
### Train an ASR directly from mismatched transcripts, based on [kaldi/egs/librispeech](https://github.com/kaldi-asr/kaldi/tree/master/egs/librispeech).

<!-- https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet -->

Mismatched transcripts are produced by people writing down what they
hear in a language L2, as if it were nonsense syllables in their own
language, English.

This has two sources of variability, which we solve separately:

- To solve **English orthography**, we align a transcript to its audio with a nonsense-English ASR.

- To solve **L2-to-English misperception**, we generate candidate L2 word transcriptions,
use them to train an L2 recognizer, and then align them to the audio.
 
We need these software components:
 
### 1. English nonsense dictionary

Make a pronunciation lexicon of English nonsense words, which Kaldi calls `lexiconp.txt`.
Its vocabulary is the space-delimited words in Turker transcripts.
For each word, use <http://www.isle.illinois.edu/sst/data/g2ps/English/English_ref_orthography_dict.html>
to find all of its pronunciations, and list them separately in `lexiconp.txt`.
The units of `English_ref_orthography_dict.txt` are designed so that you should prefer any digraph or trigraph to the single-grapheme.
To implement that, assign a probability to each pronunciation proportional to exp(-(number of entries from `English_ref_orthography.html` that were concatenated to form this candidate pronunciation)).

Scripts for this are in the subfolder [1-nonsenseDict](./1-nonsenseDict).
The script [1-nonsenseDict/split-words.rb](1-nonsenseDict/split-words.rb) will also preprocess turker transcripts (like <https://github.com/uiuc-sst/PTgen/blob/master/steps/preprocess_turker_transcripts.pl>).

### 2. English ASR and forced alignment

An English-language GMM-HMM ASR, trained using the `lexiconp.txt` from (1).
Treat every Turker transcription as an independent training token.
So if we have 3 transcriptions per utterance, then the amount of training data is 3 times the amount of audio.
Forced alignment then chooses the most likely pronunciation of each Turker nonsense word, maximizing p(audio|pronunciation). 

### 3. L2 pronunciation dictionary with English phones

Collect all available monolingual texts in L2.  LORELEI gives us 120k
words of text in each foreign language, quite a lot.  Using
*(i)* this list of words,
*(ii)* the <http://www.isle.illinois.edu/sst/data/g2ps/> L2 reference orthography,
and *(iii)* some kind of mapping from L2 phonemes to English phonemes,
generate another `lexiconp.txt`,
whose lines each contain an L2 word, a list of English phonemes, and this pronunciation's probability.

### 4. Minimum-string-edit generation of candidate L2 word transcriptions

Calculate the 10 L2-word sequences that best match the English-phone transcripts
generated by forced alignment from each transcript (thus, 30 word sequences per utterance).

### 5. L2 pronunciation dictionary with L2 phones

Convert (3), which uses English phones, to yet another `lexiconp.txt` that uses L2 phones.

### 6. Train an L2 ASR.

Use the ASR to do forced alignment of the L2 word transcriptions from (5).
