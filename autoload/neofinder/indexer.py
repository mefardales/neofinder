"""
NeoFinder File Indexer -- fast recursive file indexing via os.walk().

10-50x faster than Vim's glob('**/*') on large directories.
Builds an in-memory index that the browser uses for search.
"""

import os
import time
import threading
import vim

_index = {}
_lock = threading.Lock()
_indexing = False


def index_dir(root, max_files=50000):
    """Index a directory tree. Returns list of relative paths."""
    global _indexing
    _indexing = True
    root = os.path.normpath(root)

    try:
        ignores = vim.eval('get(g:neofinder, "ignore", [])')
    except:
        ignores = ['.git', 'node_modules', '__pycache__']

    results = []
    count = 0

    try:
        for dirpath, dirnames, filenames in os.walk(root):
            dirnames[:] = [
                d for d in dirnames
                if not any(ig.strip('/') == d for ig in ignores)
            ]

            for fname in filenames:
                if count >= max_files:
                    break
                fullpath = os.path.join(dirpath, fname)
                relpath = os.path.relpath(fullpath, root).replace('\\', '/')
                skip = False
                for ig in ignores:
                    if ig in relpath:
                        skip = True
                        break
                if skip:
                    continue
                results.append(relpath)
                count += 1
            if count >= max_files:
                break
    except PermissionError:
        pass

    with _lock:
        _index[root] = results
    _indexing = False
    return results


def index_dir_async(root, max_files=50000):
    """Index in a background thread."""
    root = os.path.normpath(root)
    with _lock:
        if root in _index:
            return
    t = threading.Thread(target=index_dir, args=(root, max_files), daemon=True)
    t.start()


def get_index(root):
    """Get cached index. Returns list or None."""
    root = os.path.normpath(root)
    with _lock:
        return _index.get(root)


def is_indexing():
    return _indexing


def clear_index(root=None):
    with _lock:
        if root:
            _index.pop(os.path.normpath(root), None)
        else:
            _index.clear()


def search_index(root, query):
    """Search index with fuzzy or glob query."""
    root = os.path.normpath(root)
    with _lock:
        files = _index.get(root, [])
    if not files:
        return []

    query_lower = query.lower()

    # Glob mode
    if '*' in query or '?' in query:
        import re
        pat = query.replace('.', r'\.')
        pat = pat.replace('**', '@@DS@@')
        pat = pat.replace('*', '[^/]*')
        pat = pat.replace('@@DS@@', '.*')
        pat = pat.replace('?', '.')
        regex = re.compile(pat + '$', re.IGNORECASE)
        return [f for f in files if regex.search(f)]

    # Fuzzy mode
    results = []
    for f in files:
        f_lower = f.lower()
        pi = 0
        for ch in f_lower:
            if pi < len(query_lower) and ch == query_lower[pi]:
                pi += 1
        if pi == len(query_lower):
            results.append(f)
    return results


def index_count(root):
    root = os.path.normpath(root)
    with _lock:
        return len(_index.get(root, []))
