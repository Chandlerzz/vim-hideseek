#!/usr/bin/env python
# -*- coding: utf-8 -*-

import vim
import re
import os
import sys
import os.path
import shlex
import argparse
import itertools
from functools import partial
# from .utils import *
# from .explorer import *
# from .manager import *
# from .asyncExecutor import AsyncExecutor


"""
let g:Lf_Extensions = {
    \ "apple": {
    \       "source": [], "grep -r '%s' *", funcref (arguments), {"command": "ls" or funcref(arguments)}
    \       "arguments": [
    \           { "name": ["--foo", "-f"], "nargs": n or "?" or "*" or "+", "help": "hehe"},
    \           { "name": ["bar"], "nargs": n or "?" or "*" or "+" }
    \       ],
    \       "format_line": funcref (line, arguments),
    \       "format_list": funcref ([], arguments),
    \       "need_exit": funcref (line, arguments),
    \       "accept": funcref (line, arguments),
    \       "preview": funcref (orig_buf_nr, orig_cursor, arguments),
    \       "supports_name_only": 0,
    \       "get_digest": funcref (line, mode),
    \       "before_enter": funcref (arguments),
    \       "after_enter": funcref (orig_buf_nr, orig_cursor, arguments),
    \       "bang_enter": funcref (orig_buf_nr, orig_cursor, arguments),
    \       "before_exit": funcref (orig_buf_nr, orig_cursor, arguments),
    \       "after_exit": funcref (arguments),
    \       "highlights_def": {
    \               "Lf_hl_apple": '^\s*\zs\d\+',
    \               "Lf_hl_appleId": '\d\+$',
    \       },
    \       "highlights_cmd": [
    \               "hi Lf_hl_apple guifg=red",
    \               "hi Lf_hl_appleId guifg=green",
    \       ],
    \       "highlight": funcref (arguments),
    \       "supports_multi": 0,
    \       "supports_refine": 0,
    \ },
    \ "orange": {}
\}
"""

def lfFunction(name):
    if lfEval("has('nvim')") == '1':
        func = partial(vim.call, name)
    else:
        func = vim.Function(name)
    return func

class LfHelpFormatter(argparse.HelpFormatter):
    def __init__(self,
                 prog,
                 indent_increment=2,
                 max_help_position=24,
                 width=105):
        super(LfHelpFormatter, self).__init__(prog, indent_increment, max_help_position, width)

gtags_usage = """
\n
Leaderf[!] gtags [-h] [--remove] [--recall]
Leaderf[!] gtags --update [--gtagsconf <FILE>] [--gtagslabel <LABEL>] [--accept-dotfiles]
                 [--skip-unreadable] [--skip-symlink [<TYPE>]] [--gtagslibpath <PATH> [<PATH> ...]]
Leaderf[!] gtags [--current-buffer | --all-buffers | --all] [--result <FORMAT>] [COMMON_OPTIONS]
Leaderf[!] gtags -d <PATTERN> [--auto-jump [<TYPE>]] [-i] [--literal] [--path-style <FORMAT>] [-S <DIR>]
                 [--append] [--match-path] [--gtagsconf <FILE>] [--gtagslabel <LABEL>] [COMMON_OPTIONS]
Leaderf[!] gtags -r <PATTERN> [--auto-jump [<TYPE>]] [-i] [--literal] [--path-style <FORMAT>] [-S <DIR>]
                 [--append] [--match-path] [--gtagsconf <FILE>] [--gtagslabel <LABEL>] [COMMON_OPTIONS]
Leaderf[!] gtags -s <PATTERN> [-i] [--literal] [--path-style <FORMAT>] [-S <DIR>] [--append]
                 [--match-path] [--gtagsconf <FILE>] [--gtagslabel <LABEL>] [COMMON_OPTIONS]
Leaderf[!] gtags -g <PATTERN> [-i] [--literal] [--path-style <FORMAT>] [-S <DIR>] [--append]
                 [--match-path] [--gtagsconf <FILE>] [--gtagslabel <LABEL>] [COMMON_OPTIONS]
Leaderf[!] gtags --by-context [--auto-jump [<TYPE>]] [-i] [--literal] [--path-style <FORMAT>] [-S <DIR>]
                 [--append] [--match-path] [--gtagsconf <FILE>] [--gtagslabel <LABEL>] [COMMON_OPTIONS]

[COMMON_OPTIONS]: [--reverse] [--stayOpen] [--input <INPUT> | --cword]
                  [--top | --bottom | --left | --right | --belowright | --aboveleft | --fullScreen]
                  [--nameOnly | --fullPath | --fuzzy | --regexMode] [--nowrap] [--next | --previous]
 \n
"""

class AnyHub(object):
    def __init__(self):
        self._managers = {}
        self._parser = None
        self._pyext_manages = {}
        self._last_cmd = None

    def _add_argument(self, parser, arg_list, positional_args):
        pass
        """
        Args:
            parser:
                an argparse object
            arg_list:
                a list of argument definition, e.g.,
                [
                    # "--big" and "--small" are mutually exclusive
                    [
                        {"name": ["--big"], "nargs": 0, "help": "big help"},
                        {"name": ["--small"], "nargs": 0, "help": "small help"},
                    ],
                    {"name": ["--tabpage"], "nargs": 1, "metavar": "<TABPAGE>"},
                ]
            positional_args[output]:
                a list of positional arguments
        """

    def _default_action(self, category, positional_args, arguments, *args, **kwargs):
        pass

    def start(self, arg_line, *args, **kwargs):
        pass

#*****************************************************
# anyHub is a singleton
#*****************************************************
anyHub = AnyHub()

__all__ = ['anyHub']
