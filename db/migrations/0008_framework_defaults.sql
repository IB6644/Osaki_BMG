-- Seed default framework definition and add candidate sections storage

alter table framework_instances
  add column if not exists candidate_sections jsonb default '{}'::jsonb;

insert into framework_definitions (id, name, sections)
values (
  '00000000-0000-0000-0000-000000000100',
  'Business Model 6-block',
  '{
    "business_overview": ["事業の概要やコンセプトを簡潔に"],
    "target_customer": ["想定顧客やユーザーペルソナ"],
    "value_proposition": ["提供する価値、顧客ベネフィット"],
    "problems_solved": ["解決したい課題やペイン"],
    "business_model": {
      "who_pays": "誰が支払うか",
      "pricing": "価格モデル/無料枠など",
      "cost_drivers": ["主なコスト"],
      "flows": [
        {"from": "顧客", "to": "事業", "type": "money", "note": "料金支払い"}
      ]
    },
    "hurdles": ["技術・規制・検証のハードル"]
  }'::jsonb
)
on conflict (id) do update set name = excluded.name;

update framework_instances
set definition_id = coalesce(definition_id, '00000000-0000-0000-0000-000000000100');
