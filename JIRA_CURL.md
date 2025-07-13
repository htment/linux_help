
Доступные проекты:

bash
curl -s -H "Authorization: Bearer BARIER_KEY" -k "https://sd.v-serv.ru/jira/rest/api/2/project" | jq


Доступные типы задач для проекта:

bash
curl -s -H "Authorization: Bearer BARIER_KEY" -k "https://sd.v-serv.ru/jira/rest/api/2/issue/createmeta?projectKeys=PLAT" | jq


Кастомные поля:

bash
curl -s -H "Authorization: Bearer BARIER_KEY" -k "https://sd.v-serv.ru/jira/rest/api/2/field" | jq





curl -s -H "Authorization: Bearer BARIER_KEY" -H "Content-Type: application/json" -k "https://sd.v-serv.ru/jira/rest/api/2/issue/PLAT-95123" -w "%{http_code}" | jq

название
curl -s -H "Authorization: Bearer BARIER_KEY" -H "Content-Type: application/json" -k "https://sd.v-serv.ru/jira/rest/api/2/issue/PLAT-95123" | jq '.fields.summary'


(Меняем "Новый заголовок тикета" на нужный текст.)
curl -X PUT \
  -H "Authorization: Bearer BARIER_KEY" \
  -H "Content-Type: application/json" \
  -k "https://sd.v-serv.ru/jira/rest/api/2/issue/PLAT-95123" \
  -d '{
    "fields": {
      "summary": "Хохленков Task1"
    }
  }'
(Меняем "Новый заголовок тикета" на нужный текст.)




# Получаем список вложений
attachments=$(curl -s -H "Authorization: Bearer BARIER_KEY" -H "Content-Type: application/json" -k "https://sd.v-serv.ru/jira/rest/api/2/issue/PLAT-95123" | jq -r '.fields.attachment[]?.id'
)
 # Удаляем каждое вложение
for attachment_id in $attachments; do
    curl -X DELETE -H "Authorization: Bearer BARIER_KEY" -k "https://sd.v-serv.ru/jira/rest/api/2/attachment/$attachment_id"
done
art@debian-sb:~$


curl -s -H "Authorization: Bearer BARIER_KEY" -k "https://sd.v-serv.ru/jira/rest/api/2/issue/PLAT-95123" | jq '.fields.components'

Создать тикет
curl -X POST \
  -H "Authorization: Bearer BARIER_KEY" \
  -H "Content-Type: application/json" \
  -k "https://sd.v-serv.ru/jira/rest/api/2/issue/" \
  -d '{
    "fields": {
       "project": {
          "key": "PLAT"
       },
       "summary": "TEST_API",
       "description": "Описание проблемы/задачи",
       "issuetype": {
          "name": "Task"
       },
       "components": [
          {"id": "145820"}
       ]
    }
  }'
