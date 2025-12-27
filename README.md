# minigit 🐙

`minigit` is a simplified Git-like version control system written in Ruby for educational and portfolio purposes.

The goal of this project is to deeply understand how Git works internally:  
staging area, commits, snapshots, hashing, and state comparison between the working tree, index, and last commit.

---

## ✨ Features

- Repository initialization (`init`)
- File staging (`add`)
- Commit creation with snapshots (`commit`)
- Commit history (`log`)
- Repository status (`status`)
  - Staged files
  - Modified but not staged files
  - Untracked files

---

## 📂 Internal Structure

```
.minigit/
├── HEAD
├── index
└── objects/
    └── <commit_hash>/
        ├── meta
        └── files/
            ├── file1.txt
            ├── file2.rb
```

## 📌 HEAD

Stores the hash of the latest commit.

## 📌 index

Represents the staging area.
Each line follows the format:
```
filename:md5_hash
```

## 📌 objects/<commit_hash>/

Each commit is stored as a full snapshot:

- meta: commit metadata
- files/: exact copies of staged files

## 🧠 Mental Model (Git-like)

```
Working Tree → Index (staging) → Commit (snapshot)
```

## 🚀 Usage

### Initialize repository
```
ruby minigit.rb init
```

### Add files
```
ruby minigit.rb add filename
```

### Create a commit
```
ruby minigit.rb commit "commit message"
```

### View commit history
```
ruby minigit.rb log
```

### Check repository status
```
ruby minigit.rb status
```

### Running tests
```
bundle install  
bundle exec rspec
```