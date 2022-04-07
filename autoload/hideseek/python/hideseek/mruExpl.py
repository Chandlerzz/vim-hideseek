
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
        self._cur_dir = ''
        self._content = []
        self._cmd_work_dir = ""
        self._curr_dir = hsGetCwd()
        self._mru_source_file = hsEval("get(g:,'hs_mru_source_file','')")

    def getContent(self, *args, **kwargs):
        content = []
        with hsOpen(self._mru_source_file, 'r+', errors='ignore') as f:
            lines = f.readlines()
            curr_dir = self._curr_dir
            for line in lines:
                if re.match(curr_dir,line):
                    line = line.split("%")[0]
                    # content.append(re.sub(curr_dir+"/","",line))
                    # the absolute path needed
                    content.append(line)
            for index in range(len(content)):
                content[index]=re.sub(curr_dir+"/","",content[index])
                # TODO need put every line to the the dictionary
                content[index] = "{}: {}".format(index+1, content[index])
            return content

    def getStlCategory(self):
        return "Mru"

    def getStlCurDir(self):
        curDir = ""
        return curDir

mruExpl = MruExplorer()

__all__ = ['mruExpl']
