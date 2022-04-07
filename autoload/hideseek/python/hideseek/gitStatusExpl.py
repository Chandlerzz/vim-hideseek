
#gitStatusExpl
#!/usr/bin/env python
# -*- coding: utf-8 -*-

# import vim
import re
import os
import os.path
import fnmatch
import time
import locale
from functools import wraps
from .explorer import *
from .utils import *

class GitStatusExplore(Explorer):
    def __init__(self):
        self._cur_dir = ''
        self._content = []
        self._cmd_work_dir = ""

    def getContent(self, *args, **kwargs):
        content = hsEval("systemlist('git status -s --untracked-files')")
        content = [ item.split(" ")[2] for item in content ]
        hsEval("hideseek#clearDict()")
        for index in range(len(content)):
            line = os.path.abspath(content[index])
            dicts ={'lrc_num':index+1,'path':line}
            hsEval("hideseek#addDict('{}',{})".format(index+1,dicts))
            content[index] = str(index+1)+": "+ content[index]
        return content

    def getStlCategory(self):
        return "gits"

    def getStlCurDir(self):
        curDir = ""
        return curDir

gitStatusExpl = GitStatusExplore()

__all__ = ['gitStatusExpl']
