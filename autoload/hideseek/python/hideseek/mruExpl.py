
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

class MruExplorer(Explorer):
    def __init__(self):
        self._content = []
        self._cmd_work_dir = ""
        self._cur_dir = ""
        self._mru_source_file = hsEval("get(g:,'hs_mru_source_file','')")

    def getContent(self, *args, **kwargs):
        content = []
        with hsOpen(self._mru_source_file, 'r+', errors='ignore') as f:
            lines = f.readlines()
            self._cur_dir = hsGetCwd()
            cur_dir = self._cur_dir
            start = 1
            hsEval("hideseek#clearDict()")
            for index in range(len(lines)):
                line = lines[index]
                if re.match(cur_dir,line):
                    line = line.split("%")[0]
                    dicts ={'lrc_num':index+1,'path':line}
                    hsEval("hideseek#addDict('{}',{})".format(start,dicts))
                    content.append(line)
                    start = start + 1
            for index in range(len(content)):
                content[index]=re.sub(cur_dir+"/","",content[index])
                content[index] = "{}: {}".format(index+1, content[index])
            return content

    def getStlCategory(self):
        return "mru"

    def getStlCurDir(self):
        curDir = ""
        return curDir

mruExpl = MruExplorer()

__all__ = ['mruExpl']
