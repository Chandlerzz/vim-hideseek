
#mrutreeExpl
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

class MruExplorer(Explorer):
    def __init__(self):
        self._cur_dir = ''
        self._content = []
        self._cmd_work_dir = ""

    def getContent(self, *args, **kwargs):
        content = ""
        return content

    def getStlCategory(self):
        return "Mru"

    def getStlCurDir(self):
        curDir = ""
        return curDir
