# ADF 구조 예시 (issue-refine 보조)

ADF 구조 예시:

```json
{
  "version": 1,
  "type": "doc",
  "content": [
    {"type": "heading", "attrs": {"level": 2}, "content": [{"type": "text", "text": "배경"}]},
    {"type": "paragraph", "content": [{"type": "text", "text": "{배경 내용}"}]},
    {"type": "heading", "attrs": {"level": 2}, "content": [{"type": "text", "text": "구현 범위"}]},
    {"type": "bulletList", "content": [
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "포함: {내용}"}]}]},
      {"type": "listItem", "content": [{"type": "paragraph", "content": [{"type": "text", "text": "제외: {내용}"}]}]}
    ]},
    {"type": "heading", "attrs": {"level": 2}, "content": [{"type": "text", "text": "수락 조건"}]},
    {"type": "taskList", "attrs": {"localId": "{issueKey}-tasklist"},
      "content": [
        {"type": "taskItem", "attrs": {"localId": "{issueKey}-task-1", "state": "TODO"},
          "content": [{"type": "text", "text": "{조건 1}"}]},
        {"type": "taskItem", "attrs": {"localId": "{issueKey}-task-2", "state": "TODO"},
          "content": [{"type": "text", "text": "{조건 2}"}]}
      ]
    }
  ]
}
```
