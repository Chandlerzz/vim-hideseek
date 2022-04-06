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
from .utils import *
from .explorer import *
# from .manager import *
# from .asyncExecutor import AsyncExecutor


"""
let g:Hs_Extensions = {
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
    \               "Hs_hl_apple": '^\s*\zs\d\+',
    \               "Hs_hl_appleId": '\d\+$',
    \       },
    \       "highlights_cmd": [
    \               "hi Hs_hl_apple guifg=red",
    \               "hi Hs_hl_appleId guifg=green",
    \       ],
    \       "highlight": funcref (arguments),
    \       "supports_multi": 0,
    \       "supports_refine": 0,
    \ },
    \ "orange": {}
\}
"""

def lfFunction(name):
    if hsEval("has('nvim')") == '1':
        func = partial(vim.call, name)
    else:
        func = vim.Function(name)
    return func

class HsHelpFormatter(argparse.HelpFormatter):
    def __init__(self,
                 prog,
                 indent_increment=2,
                 max_help_position=24,
                 width=105):
        super(HsHelpFormatter, self).__init__(prog, indent_increment, max_help_position, width)

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

class OptionalAction(argparse.Action):
    def __init__(self,
                 option_strings,
                 dest,
                 nargs=None,
                 const=None,
                 default=None,
                 type=None,
                 choices=None,
                 required=False,
                 help=None,
                 metavar=None):
        super(OptionalAction, self).__init__(option_strings=option_strings,
                                             dest=dest,
                                             nargs=nargs,
                                             const=const,
                                             default=default,
                                             type=type,
                                             choices=choices,
                                             required=required,
                                             help=help,
                                             metavar=metavar)

    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, [] if values is None else [values])

class HsShlex(shlex.shlex):
    """
    shlex.split(r' "aaa\"bbb" ', posix=False) produces the result ['"aaa\\"', 'bbb"'],
    which is not expected.
    I want the result to be ['"aaa\\"bbb"']
    """
    def read_token(self):
        quoted = False
        escapedstate = ' '
        while True:
            nextchar = self.instream.read(1)
            if nextchar == '\n':
                self.lineno = self.lineno + 1
            if self.debug >= 3:
                print("shlex: in state", repr(self.state), \
                      "I see character:", repr(nextchar))
            if self.state is None:
                self.token = ''        # past end of file
                break
            elif self.state == ' ':
                if not nextchar:
                    self.state = None  # end of file
                    break
                elif nextchar in self.whitespace:
                    if self.debug >= 2:
                        print("shlex: I see whitespace in whitespace state")
                    if self.token or (self.posix and quoted):
                        break   # emit current token
                    else:
                        continue
                elif self.posix and nextchar in self.escape:
                    escapedstate = 'a'
                    self.state = nextchar
                elif nextchar in self.wordchars:
                    self.token = nextchar
                    self.state = 'a'
                elif nextchar in self.quotes:
                    if not self.posix:
                        self.token = nextchar
                    self.state = nextchar
                elif self.whitespace_split:
                    self.token = nextchar
                    self.state = 'a'
                else:
                    self.token = nextchar
                    if self.token or (self.posix and quoted):
                        break   # emit current token
                    else:
                        continue
            elif self.state in self.quotes:
                quoted = True
                if not nextchar:      # end of file
                    if self.debug >= 2:
                        print("shlex: I see EOF in quotes state")
                    # XXX what error should be raised here?
                    raise ValueError("No closing quotation")
                if nextchar == self.state:
                    if not self.posix:
                        self.token = self.token + nextchar
                        self.state = ' '
                        break
                    else:
                        self.state = 'a'
                elif self.posix and nextchar in self.escape and \
                     self.state in self.escapedquotes:
                    escapedstate = self.state
                    self.state = nextchar
                else:
                    if nextchar in self.escape:
                        escapedstate = self.state
                        self.state = nextchar
                    self.token = self.token + nextchar
            elif self.state in self.escape:
                if not nextchar:      # end of file
                    if self.debug >= 2:
                        print("shlex: I see EOF in escape state")
                    # XXX what error should be raised here?
                    raise ValueError("No escaped character")
                # # In posix shells, only the quote itself or the escape
                # # character may be escaped within quotes.
                # if escapedstate in self.quotes and \
                #    nextchar != self.state and nextchar != escapedstate:
                #     self.token = self.token + self.state
                self.token = self.token + nextchar
                self.state = escapedstate
            elif self.state == 'a':
                if not nextchar:
                    self.state = None   # end of file
                    break
                elif nextchar in self.whitespace:
                    if self.debug >= 2:
                        print("shlex: I see whitespace in word state")
                    self.state = ' '
                    if self.token or (self.posix and quoted):
                        break   # emit current token
                    else:
                        continue
                elif self.posix and nextchar in self.quotes:
                    self.state = nextchar
                elif self.posix and nextchar in self.escape:
                    escapedstate = 'a'
                    self.state = nextchar
                elif nextchar in self.wordchars or nextchar in self.quotes \
                    or self.whitespace_split:
                    self.token = self.token + nextchar
                else:
                    self.pushback.appendleft(nextchar)
                    if self.debug >= 2:
                        print("shlex: I see punctuation in word state")
                    self.state = ' '
                    if self.token:
                        break   # emit current token
                    else:
                        continue
        result = self.token
        self.token = ''
        if self.posix and not quoted and result == '':
            result = None
        if self.debug > 1:
            if result:
                print("shlex: raw token=" + repr(result))
            else:
                print("shlex: raw token=EOF")
        return result

    def split(self):
        self.whitespace_split = True
        return list(self)
class HsHelpFormatter(argparse.HelpFormatter):
    def __init__(self,
                 prog,
                 indent_increment=2,
                 max_help_position=24,
                 width=105):
        super(HsHelpFormatter, self).__init__(prog, indent_increment, max_help_position, width)

class AnyHub(object):
    def __init__(self):
        self._managers = {}
        self._parser = None
        self._pyext_manages = {}
        self._last_cmd = None

    def _add_argument(self, parser, arg_list, positional_args):
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
        for arg in arg_list:
            if isinstance(arg, list):
                group = parser.add_mutually_exclusive_group()
                self._add_argument(group, arg, positional_args)
            else:
                arg_name = arg["name"][0]
                metavar = arg.get("metavar", None)
                if arg_name.startswith("-"):
                    if metavar is None:
                        metavar = '<' + arg_name.lstrip("-").upper().replace("-", "_") + '>'
                    add_argument = partial(parser.add_argument, metavar=metavar, dest=arg_name)
                else:
                    positional_args.append(arg["name"][0])
                    add_argument = partial(parser.add_argument, metavar=metavar)

                nargs = arg.get("nargs", None)
                if nargs is not None:
                    try:
                        nargs = int(arg["nargs"])
                    except: # ? * +
                        nargs = arg["nargs"]

                choices = arg.get("choices", None)
                if nargs == 0:
                    add_argument(*arg["name"], action='store_const', const=[],
                                 default=argparse.SUPPRESS, help=arg.get("help", ""))
                elif nargs == "?":
                    add_argument(*arg["name"], choices=choices, action=OptionalAction, nargs=nargs,
                                 default=argparse.SUPPRESS, help=arg.get("help", ""))
                else:
                    add_argument(*arg["name"], choices=choices, nargs=nargs, action=arg.get("action", None), default=argparse.SUPPRESS,
                                 help=arg.get("help", ""))

    def _default_action(self, category, positional_args, arguments, *args, **kwargs):
        if category == "mru":
            from .mruExpl import mruExpl 
            manager = mruExpl
        elif category == "gits":
            from .gitStatusExpl import gitStatusExpl 
            manager = gitStatusExpl
        elif category == "mrutree":
            from .mruTreeExpl import mruTreeExpl
            manager = mruTreeExpl
        content = manager.getContent()
         hsEval("hideseek#setmlines({})".format(content))
        print("hideseek#setmlines({})".format(content))
        header = manager.getStlCategory()
        content.insert(0,header)
        bufnr = hsEval("hideseek#getBufnr()")
        linenr = hsEval("len(getbufline({},0,'$'))".format(bufnr))
        hsEval("hideseek#clearAllLines({},{})".format(bufnr,linenr))
        for line in content:
            linenr = hsEval("hideseek#getbuflinenr({})".format(bufnr))
            hsEval("appendbufline({},{},\"{}\")".format(bufnr,linenr,line))


    def start(self, arg_line, *args, **kwargs):
        if self._parser is None:
            self._parser = argparse.ArgumentParser(prog="Hideseek[!]", formatter_class=HsHelpFormatter, epilog="If [!] is given, enter normal mode directly.")
            self._add_argument(self._parser, hsEval("g:Hs_CommonArguments"), [])
            subparsers = self._parser.add_subparsers(title="subcommands", description="", help="")
            extensions = itertools.chain(hsEval("keys(g:Hs_Extensions)"), hsEval("keys(g:Hs_PythonExtensions)"))
            for category in itertools.chain(extensions,
                    (i for i in hsEval("keys(g:Hs_Arguments)") if i not in extensions)):
                positional_args = []
                if hsEval("has_key(g:Hs_Extensions, '%s')" % category) == '1':
                    help = hsEval("get(g:Hs_Extensions['%s'], 'help', '')" % category)
                    arg_def = hsEval("get(g:Hs_Extensions['%s'], 'arguments', [])" % category)
                elif hsEval("has_key(g:Hs_PythonExtensions, '%s')" % category) == '1':
                    help = hsEval("get(g:Hs_PythonExtensions['%s'], 'help', '')" % category)
                    arg_def = hsEval("get(g:Hs_PythonExtensions['%s'], 'arguments', [])" % category)
                else:
                    help = hsEval("g:Hs_Helps['%s']" % category)
                    arg_def = hsEval("g:Hs_Arguments['%s']" % category)

                if category == 'gtags':
                    parser = subparsers.add_parser(category, usage=gtags_usage, formatter_class=HsHelpFormatter, help=help, epilog="If [!] is given, enter normal mode directly.")
                else:
                    parser = subparsers.add_parser(category, help=help, formatter_class=HsHelpFormatter, epilog="If [!] is given, enter normal mode directly.")
                group = parser.add_argument_group('specific arguments')
                self._add_argument(group, arg_def, positional_args)

                group = parser.add_argument_group("common arguments")
                self._add_argument(group, hsEval("g:Hs_CommonArguments"), positional_args)

                parser.set_defaults(start=partial(self._default_action, category, positional_args))

        try:
            # # do not produce an error when extra arguments are present
            # the_args = self._parser.parse_known_args(HsShlex(arg_line, posix=False).split())[0]

            # produce an error when extra arguments are present
            raw_args = HsShlex(arg_line, posix=False).split()

            # ArgumentParser.add_subparsers([title][, description][, prog][, parser_class][, action][, option_string][, dest][, required][, help][, metavar])
            #   - required - Whether or not a subcommand must be provided, by default False (added in 3.7)
            if sys.version_info < (3, 7):
                if "--recall" in raw_args and len([i for i in raw_args if not i.startswith('-')]) == 0:
                    if self._last_cmd:
                        self._last_cmd({'--recall': []}, *args, **kwargs)
                    else:
                        lfPrintError("LeaderF has not been used yet!")
                    return
                elif "--next" in raw_args and len([i for i in raw_args if not i.startswith('-')]) == 0:
                    if self._last_cmd:
                        self._last_cmd({'--next': []}, *args, **kwargs)
                    else:
                        lfPrintError("LeaderF has not been used yet!")
                    return
                elif "--previous" in raw_args and len([i for i in raw_args if not i.startswith('-')]) == 0:
                    if self._last_cmd:
                        self._last_cmd({'--previous': []}, *args, **kwargs)
                    else:
                        lfPrintError("LeaderF has not been used yet!")
                    return

            the_args = self._parser.parse_args(raw_args)
            arguments = vars(the_args)
            arguments = arguments.copy()
            if "start" in arguments:
                del arguments["start"]
                arguments["arg_line"] = arg_line
                the_args.start(arguments, *args, **kwargs)
                self._last_cmd = the_args.start
            elif "--recall" in arguments:
                if self._last_cmd:
                    self._last_cmd(arguments, *args, **kwargs)
                else:
                    lfPrintError("LeaderF has not been used yet!")
            elif "--next" in arguments:
                if self._last_cmd:
                    self._last_cmd(arguments, *args, **kwargs)
                else:
                    lfPrintError("LeaderF has not been used yet!")
            elif "--previous" in arguments:
                if self._last_cmd:
                    self._last_cmd(arguments, *args, **kwargs)
                else:
                    lfPrintError("LeaderF has not been used yet!")
        # except ValueError as e:
        #     lfPrintError(e)
        #     return
        except SystemExit:
            return

#*****************************************************
# anyHub is a singleton
#*****************************************************
anyHub1 = AnyHub()

__all__ = ['anyHub1']
