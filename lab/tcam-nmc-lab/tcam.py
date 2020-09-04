"""
Created on August 13 14:35, 2020

@author: fassial
"""

class TCAM:

    def __init__(self, words, mems, prior = 2):
        self.words = words
        self.mems = mems
        self.prior = prior

    def query(self, word):
        res = []
        for i in range(self.words.shape[0]):
            if self._ternary_match(word, self.words[i]):
                res.append(i)
                if len(res) == self.prior: break
        return self.mems[res]

    def _ternary_match(self, word, _word):
        for i in range(_word.shape[0]):
            if _word[i] == 0: continue
            elif _word[i] == 1 and word[i] == 1: continue
            elif _word[i] == -1 and word[i] == 0: continue
            else: return False
        return True
