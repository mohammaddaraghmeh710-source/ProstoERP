// Run with Node to regenerate the two importable mobile developer artifacts.
const fs=require('fs'),path=require('path');
const integer={type:'integer',format:'int32',minimum:1},text={type:'string'},bool={type:'boolean'};
const event={EmployeeNumber:integer,OperationID:{type:'string',format:'uuid'},OccurredAt:{type:'string',format:'date-time',description:'Actual device event time with explicit UTC offset. Reuse unchanged when retrying.'}};
const create={...event,TypeID:integer,TopicID:integer,Title:{...text,maxLength:300},Details:{...text,maxLength:10000},DiscloseIdentity:bool,RecipientTypeID:integer};
const action={...event,Action:{type:'string',enum:['transfer','close']},Comment:{...text,maxLength:10000},RowVersion:{type:'string',format:'byte',description:'Base64 eight-byte version from last open.'},RecipientTypeID:{...integer,description:'Required for transfer; omit for close.'}};
const object=(properties,required=Object.keys(properties))=>({type:'object',properties,required,additionalProperties:false});
const ref=name=>({$ref:'#/components/schemas/'+name});
const array=items=>({type:'array',items});
const query=(name,schema,required=false)=>({name,in:'query',required,schema});
const employee=query('employeeNumber',integer,true),id={name:'id',in:'path',required:true,schema:integer};
const paging=[query('page',{...integer,default:1,maximum:1000000}),query('pageSize',{...integer,default:20,maximum:100})];
const genericRow={type:'object',additionalProperties:true};
const nullableText={type:'string',nullable:true};
const schemas={
 Event:object(event),Create:object(create),Action:object(action,Object.keys(action).filter(k=>k!=='RecipientTypeID')),
 Routing:object({EmployeeNumber:integer,RecipientTypeID:integer,RequestID:integer},['EmployeeNumber','RecipientTypeID']),
 Error:object({Success:{type:'boolean',enum:[false]},Error:object({Code:text,Message:text})}),
 Saved:object({RequestID:integer,Replayed:bool,Message:text}),
 Counts:object(Object.fromEntries(['TotalRequests','SentRequests','ActiveRequests','ClosedRequests','ActionRequiredRequests'].map(k=>[k,{type:'integer',minimum:0}]))),
 Attachment:object({ID:integer,File_Type:text,FileSize:{type:'integer',format:'int64'},GroupID:{type:'string',format:'uuid',nullable:true},FileName:text,PreviewUrl:{type:'string',format:'uri'},DownloadUrl:{type:'string',format:'uri'}}),
 Workflow:object({GroupID:{type:'string',format:'uuid'},ActionType:{type:'integer',enum:[1,2,3]},AddedDate:{type:'string',format:'date-time'},Comment:nullableText,SenderName:nullableText,ReceiverNames:nullableText}),
 Contact:object({SourceType:{type:'integer',enum:[1,2]},BrandName:nullableText,BranchName:nullableText,CapturedAt:{type:'string',format:'date-time',nullable:true},IsBackfilled:bool,CanViewContact:bool,ApplicantName:nullableText,ApplicantNameEn:nullableText,ApplicantEmployeeNumber:{type:'integer',nullable:true},ApplicantPhone:nullableText,ApplicantMobile:nullableText,ApplicantEmail:nullableText}),
 AllowedAction:object({Code:{type:'string',enum:['transfer','close']},Title:text,CommentRequired:bool,RecipientRequired:bool}),
 Detail:object({Request:genericRow,Contact:ref('Contact'),Attachments:array(ref('Attachment')),Workflow:array(ref('Workflow')),AllowedActions:array(ref('AllowedAction')),RecipientTypes:array(genericRow),Replayed:bool}),
 Requests:object({Counts:ref('Counts'),TotalItems:{type:'integer'},Page:integer,PageSize:integer,Items:array(genericRow)}),
 Notifications:object({UnreadCount:{type:'integer'},TotalItems:{type:'integer'},Page:integer,PageSize:integer,Items:array(genericRow)}),
 Options:object({Types:array(genericRow),Topics:array(genericRow),Permissions:genericRow,RecipientTypes:array(genericRow),Statuses:array(genericRow),FileRules:genericRow,MaxTitleLength:integer,MaxDetailsLength:integer,MaxCommentLength:integer}),
 RoutingResult:object({RecipientTypeID:integer,Recipients:array(genericRow),CanSend:bool,IsFallback:bool,Message:text})
};
const response=name=>({description:'Success',content:{'application/json':{schema:object({Success:{type:'boolean',enum:[true]},Data:ref(name)})}}});
const errors=Object.fromEntries([400,401,403,404,409,413,415,500].map(code=>[code,{description:'See Feedback-API.md for Error.Code behavior.',content:{'application/json':{schema:ref('Error')}}}]));
const json=name=>({required:true,content:{'application/json':{schema:ref(name)}}});
const multipart=name=>({required:true,content:{'multipart/form-data':{schema:object({data:ref(name),files:{type:'array',maxItems:5,items:{type:'string',format:'binary'},description:'Optional PDF or image files, maximum 10MiB each.'}},['data']),encoding:{data:{contentType:'application/json'}}}}});
const definitions=[
 ['get','/options','getFeedbackOptions','Dynamic request form options','Options',[employee,query('type',{type:'integer',minimum:0,default:0})]],
 ['post','/routing-preview','previewFeedbackRouting','Resolve all permitted recipients and fallback','RoutingResult',[],json('Routing')],
 ['get','/requests','listFeedbackRequests','Unified personal follow-up and five counts','Requests',[employee,...paging,query('search',{type:'string',maxLength:300}),query('type',{type:'integer',minimum:0,default:0}),query('status',{type:'integer',enum:[0,1,2,3,4],default:0}),query('scope',{type:'string',enum:['all','sent','action','active','closed'],default:'all'})]],
 ['post','/requests','createFeedbackRequest','Submit data and files atomically; server captures employee snapshot','Saved',[],multipart('Create')],
 ['post','/requests/{id}/open','openFeedbackRequest','Read detail, log actual view, mark this request notifications read','Detail',[id],json('Event')],
 ['post','/requests/{id}/actions','actOnFeedbackRequest','Transfer or close with required explanation and optional files','Saved',[id],multipart('Action')],
 ['get','/attachments/{id}','getFeedbackAttachment','Authorized preview or download of actual file bytes',null,[id,employee,query('download',{type:'boolean',default:false})]],
 ['get','/notifications','listFeedbackNotifications','List notifications without marking read','Notifications',[employee,...paging,query('unreadOnly',{type:'boolean',default:false})]]
];
const paths={};
for(const [method,url,operationId,summary,schema,parameters,body] of definitions){
 (paths[url]??={})[method]={operationId,summary,tags:['Employee feedback'],parameters,responses:{200:schema?response(schema):{description:'Private file content; Bearer required. Inline by default; download=true sets attachment disposition.',content:Object.fromEntries(['application/pdf','image/png','image/jpeg','image/gif','application/octet-stream'].map(mime=>[mime,{schema:{type:'string',format:'binary'}}]))},...errors},...(body?{requestBody:body}:{})};
}
const api={openapi:'3.0.3',info:{title:'Prosto Employee Feedback Mobile API',version:'1.0.0',description:'Server-owned routing, permissions, employee snapshots, file persistence and audit logs. No mobile statistics, general logs, standalone notification-read or separate uploads. See Feedback-API.md.'},servers:[{url:'https://{host}/api/v1/feedback',variables:{host:{default:'localhost',description:'Replace with the deployed HTTPS API host.'}}}],security:[{Bearer:[]}],paths,components:{securitySchemes:{Bearer:{type:'http',scheme:'bearer',description:'AccessToken from POST /api/Users/Login'}},schemas}};
fs.writeFileSync(path.join(__dirname,'Feedback.openapi.json'),JSON.stringify(api,null,2)+'\n');
const variables=['baseUrl','username','password','deviceID','appVersion','devicePlatform','deviceModel','osVersion','employeeNumber','typeID','topicID','recipientTypeID','requestID','attachmentID','rowVersion','token','createOperationID','createOccurredAt','openOperationID','openOccurredAt','actionOperationID','actionOccurredAt'];
const values={baseUrl:'https://localhost',typeID:'1',topicID:'1',recipientTypeID:'1',appVersion:'1.0.0',devicePlatform:'Android',deviceModel:'Postman test device',osVersion:'14'};
const base='{{baseUrl}}/api/v1/feedback';
const model=(kind,extra)=>`{\n  "EmployeeNumber": {{employeeNumber}},\n  "OperationID": "{{${kind}OperationID}}",\n  "OccurredAt": "{{${kind}OccurredAt}}"${extra?' ,\n  '+extra:''}\n}`;
const script=(listen,exec)=>({listen,script:{type:'text/javascript',exec}});
const initialize=kind=>script('prerequest',[
 `// Clear these two collection variables before a NEW operation; keep them for retries.`,
 `if (!pm.collectionVariables.get('${kind}OperationID')) pm.collectionVariables.set('${kind}OperationID', pm.variables.replaceIn('{{$guid}}'));`,
 `if (!pm.collectionVariables.get('${kind}OccurredAt')) pm.collectionVariables.set('${kind}OccurredAt', new Date().toISOString());`
]);
const item=(name,method,url,body,events=[])=>({name,event:events,request:{method,header:[{key:'Accept',value:'application/json'},...(body?.mode==='raw'?[{key:'Content-Type',value:'application/json'}]:[])],url,description:'See Feedback-API.md. Use the signed-in employee number. Files require the same Bearer authentication.',...(body?{body}:{})}});
const raw=raw=>({mode:'raw',raw,options:{raw:{language:'json'}}});
const form=data=>({mode:'formdata',formdata:[{key:'data',value:data,type:'text',contentType:'application/json'},{key:'files',type:'file',src:[],disabled:true,description:'Enable and select up to five images/PDF files. Keep files unchanged on retries.'}]});
const saveRequest=script('test',[`if (pm.response.code===200) { const d=pm.response.json().Data; pm.collectionVariables.set('requestID',d.RequestID); }`]);
const collection={info:{name:'Prosto - Employee Feedback',schema:'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',description:'Eight mobile feedback endpoints plus existing login. Set baseUrl to the API HTTPS origin. Clear only the operation ID/time pair before a new operation; retain for retries. See Feedback-API.md.'},auth:{type:'bearer',bearer:[{key:'token',value:'{{token}}',type:'string'}]},variable:variables.map(key=>({key,value:values[key]||'',type:'string'})),item:[
 {...item('Login (existing API)','POST','{{baseUrl}}/api/Users/Login',raw('{"Username":"{{username}}","Password":"{{password}}","AppVersion":"{{appVersion}}","Device":{"DeviceID":"{{deviceID}}","Platform":"{{devicePlatform}}","Model":"{{deviceModel}}","OSVersion":"{{osVersion}}","MACID":null}}'),[script('prerequest',[`if(!pm.collectionVariables.get('deviceID'))pm.collectionVariables.set('deviceID',pm.variables.replaceIn('{{$guid}}'));`]),script('test',[`if(pm.response.code===200){const d=pm.response.json().Data;pm.collectionVariables.set('token',d.AccessToken);pm.collectionVariables.set('employeeNumber',d.User.Employee_Number);}`])]),auth:{type:'noauth'}},
 item('1 - Form options','GET',base+'/options?employeeNumber={{employeeNumber}}&type=0'),
 item('2 - Routing preview','POST',base+'/routing-preview',raw('{"EmployeeNumber":{{employeeNumber}},"RecipientTypeID":{{recipientTypeID}}}')),
 item('3 - Follow-up','GET',base+'/requests?employeeNumber={{employeeNumber}}&page=1&pageSize=20&scope=all'),
 item('4 - Submit request and files','POST',base+'/requests',form(model('create','"TypeID":{{typeID}}, "TopicID":{{topicID}}, "Title":"ملاحظة حول بيئة العمل", "Details":"تفاصيل الطلب", "DiscloseIdentity":false, "RecipientTypeID":{{recipientTypeID}}')),[initialize('create'),saveRequest]),
 item('5 - Open request details','POST',base+'/requests/{{requestID}}/open',raw(model('open')),[initialize('open'),script('test',[`if(pm.response.code===200){const d=pm.response.json().Data;pm.collectionVariables.set('rowVersion',d.Request.RowVersion);if(d.Attachments.length)pm.collectionVariables.set('attachmentID',d.Attachments[0].ID);}`])]),
 item('6 - Close request and attach files','POST',base+'/requests/{{requestID}}/actions',form(model('action','"Action":"close", "Comment":"تمت المتابعة وإغلاق الطلب.", "RowVersion":"{{rowVersion}}"')),[initialize('action')]),
 item('6 - Transfer request and attach files','POST',base+'/requests/{{requestID}}/actions',form(model('action','"Action":"transfer", "Comment":"يرجى المتابعة.", "RowVersion":"{{rowVersion}}", "RecipientTypeID":{{recipientTypeID}}')),[initialize('action')]),
 item('7 - Preview attachment','GET',base+'/attachments/{{attachmentID}}?employeeNumber={{employeeNumber}}&download=false'),
 item('8 - Notifications','GET',base+'/notifications?employeeNumber={{employeeNumber}}&page=1&pageSize=20&unreadOnly=false')
]};
collection.item[0].request.auth={type:'noauth'};delete collection.item[0].auth;
fs.writeFileSync(path.join(__dirname,'Prosto-Feedback.postman_collection.json'),JSON.stringify(collection,null,2)+'\n');
console.log('Generated OpenAPI (8 operations) and Postman collection.');
