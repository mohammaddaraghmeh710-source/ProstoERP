const fs=require('fs'),path=require('path');
const ref=n=>({$ref:'#/components/schemas/'+n});
const text={type:'string'},int={type:'integer',format:'int32'},date={type:'string',format:'date-time'},bool={type:'boolean'};
const properties={ID:int,Title:text,Summary:text,CircularDate:{type:'string',format:'date'},StartUtc:date,EndUtc:date,IsEnabled:bool,AllowDownload:bool,Audience:{type:'string',enum:['all','roles','organization']},FileName:text,FileSizeBytes:int,Version:int,ModifiedUtc:date,CreatedUtc:date,IsRead:bool,FirstReadUtc:{...date,nullable:true},LastReadUtc:{...date,nullable:true},Status:{type:'string',enum:['active']},FileEndpoint:text};
const schemas={Circular:{type:'object',properties},Error:{type:'object',properties:{Success:{type:'boolean',enum:[false]},Error:{type:'object',properties:{Code:text,Message:text}}}},
 FileEvent:{type:'object',required:['EmployeeNumber','Action','EventID'],properties:{EmployeeNumber:{...int,minimum:1},Action:{type:'string',enum:['view','download']},EventID:{type:'string',format:'uuid',description:'New UUID per user operation; reuse for retries of that operation.'},OccurredAt:{...date,nullable:true,description:'Optional client time; server UTC is authoritative.'}}}};
const employee={name:'employeeNumber',in:'query',required:true,schema:{...int,minimum:1}};
const id={name:'id',in:'path',required:true,schema:{...int,minimum:1}};
const errors=Object.fromEntries([400,401,403,404,409,500].map(s=>[s,{description:'See Circulars-API.md error codes',content:{'application/json':{schema:ref('Error')}}}]));
const success=schema=>({description:'Successful response',content:{'application/json':{schema:{type:'object',properties:{Success:{type:'boolean',enum:[true]},Data:schema}}}}});
const api={openapi:'3.0.3',info:{title:'Prosto Employee Circulars API',version:'1.0.0',description:'Active targeted circulars. File operations validate access, log the operation, and mark the current version read. List/detail metadata does not mark read. Approved mobile device Bearer token required.'},
 servers:[{url:'https://{host}',variables:{host:{default:'api.example.com'}}}],security:[{BearerAuth:[]}],components:{securitySchemes:{BearerAuth:{type:'http',scheme:'bearer'}},schemas},paths:{
 '/api/v1/circulars':{get:{operationId:'listCirculars',parameters:[employee,{name:'page',in:'query',schema:{...int,minimum:1,maximum:100000,default:1}},{name:'pageSize',in:'query',schema:{...int,minimum:1,maximum:100,default:20}},{name:'search',in:'query',schema:{type:'string',maxLength:250}},{name:'unreadOnly',in:'query',schema:{type:'boolean',default:false}}],responses:{200:success({type:'object',properties:{Counts:{type:'object',properties:{Total:int,Unread:int,Active:int}},TotalItems:int,Page:int,PageSize:int,Items:{type:'array',items:ref('Circular')}}}),...errors}}},
 '/api/v1/circulars/{id}':{get:{operationId:'circularDetails',parameters:[id,employee],responses:{200:success(ref('Circular')),...errors}}},
 '/api/v1/circulars/{id}/file':{post:{operationId:'circularFile',parameters:[id],requestBody:{required:true,content:{'application/json':{schema:ref('FileEvent')}}},responses:{200:{description:'Raw PDF bytes. Action=view: inline; action=download: attachment. No JSON success envelope.',headers:{'Content-Disposition':{schema:text},'X-Circular-Version':{schema:int},'Cache-Control':{schema:text}},content:{'application/pdf':{schema:{type:'string',format:'binary'}}}},...errors}}}
}};
fs.writeFileSync(path.join(__dirname,'Circulars.openapi.json'),JSON.stringify(api,null,2)+'\n');
const base='{{base_url}}';
const request=(name,method,url,body)=>({name,request:{method,header:[{key:'Accept',value:body?'application/pdf, application/json':'application/json'},...(body?[{key:'Content-Type',value:'application/json'}]:[])],url:base+url,...(body?{body:{mode:'raw',raw:JSON.stringify(body,null,2),options:{raw:{language:'json'}}}}:{})}});
const postman={info:{name:'Prosto - التعاميم',schema:'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',description:'Use an approved-device token from Get_user. Supply the employee number belonging to that token. File success is binary PDF; errors are JSON. Reuse event_id only for retries.'},
 auth:{type:'bearer',bearer:[{key:'token',value:'{{access_token}}',type:'string'}]},
 variable:[['base_url','https://api.example.com'],['access_token',''],['employee_number',''],['circular_id',''],['event_id','']].map(([key,value])=>({key,value})),
 item:[request('1 - التعاميم الفعالة','GET','/api/v1/circulars?employeeNumber={{employee_number}}&page=1&pageSize=20&unreadOnly=false'),
 request('2 - تفاصيل التعميم دون تسجيل قراءة','GET','/api/v1/circulars/{{circular_id}}?employeeNumber={{employee_number}}'),
 ...['view','download'].map(action=>request(action==='view'?'3 - مشاهدة PDF وتسجيل القراءة':'4 - تنزيل PDF وتسجيل القراءة','POST','/api/v1/circulars/{{circular_id}}/file',{EmployeeNumber:'{{employee_number}}',Action:action,EventID:'{{event_id}}',OccurredAt:'{{$isoTimestamp}}'}))]};
for(const item of postman.item.filter(x=>x.request.method==='POST'))item.event=[{listen:'prerequest',script:{type:'text/javascript',exec:["const eventId = pm.collectionVariables.get('event_id') || pm.variables.replaceIn('{{$guid}}');", "pm.variables.set('event_id', eventId);", "pm.collectionVariables.set('last_event_id', eventId);"]}}];
fs.writeFileSync(path.join(__dirname,'Prosto-Circulars.postman_collection.json'),JSON.stringify(postman,null,2)+'\n');
console.log('Generated Circulars OpenAPI and Postman.');
