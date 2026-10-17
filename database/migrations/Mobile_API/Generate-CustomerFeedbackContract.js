const fs=require('fs'),path=require('path');
const str={type:'string'},int={type:'integer',format:'int32',minimum:1};
const obj=(properties,required=Object.keys(properties))=>({type:'object',properties,required,additionalProperties:false});
const ref=name=>({$ref:'#/components/schemas/'+name});
const array=items=>({type:'array',items});
const labels={ID:int,Title_Ar:str,Title_En:str};
const input={OperationID:{type:'string',format:'uuid'},OccurredAt:{type:'string',format:'date-time'},TypeID:int,TopicID:int,BrandID:int,BranchID:int,Name:{type:'string',maxLength:200},Mobile:{type:'string',maxLength:30,description:'7 to 15 digits, with optional leading +, spaces, parentheses or hyphens.'},Email:{type:'string',format:'email',nullable:true,maxLength:254},Title:{type:'string',maxLength:300},Details:{type:'string',maxLength:10000},DiscloseIdentity:{type:'boolean'}};
const error=obj({Success:{type:'boolean',enum:[false]},Error:obj({Code:str,Message:str})});
const fileRules=obj({MaxFiles:int,MaxFileBytes:int,MaxImagePixels:int,Extensions:array(str)});
const schemas={Error:error,CustomerCreate:obj(input,Object.keys(input).filter(x=>x!=='Email')),
 Saved:obj({RequestID:int,SourceType:{type:'integer',enum:[2]},Replayed:{type:'boolean'},Message:str}),
 Options:obj({Types:array(obj(labels)),Brands:array(obj(labels)),Branches:array(obj({...labels,BrandID:int})),Topics:array(obj({...labels,Type:int,BrandID:int})),SourceType:{type:'integer',enum:[2]},RecipientTitle:str,FileRules:fileRules,RequiredContactFields:array(str),MaxTitleLength:int,MaxDetailsLength:int})};
const ok=name=>({description:'Success',content:{'application/json':{schema:obj({Success:{type:'boolean',enum:[true]},Data:ref(name)})}}});
const errors=Object.fromEntries([400,403,409,413,415,429,500].map(code=>[code,{description:code===429?'Rate limit: observe Retry-After seconds.':'See Customer-Feedback-API.md.',...(code===429?{headers:{'Retry-After':{schema:{type:'integer'},description:'Seconds until the current limit window expires.'}}}:{}),content:{'application/json':{schema:ref('Error')}}}]));
const api={openapi:'3.0.3',info:{title:'Prosto Customer Feedback API',version:'1.0.0',description:'Public HTTPS catalog and submission; no login or employee number. Server owns validation, snapshots, administrator routing, files and audit. No public request-detail or attachment access.'},servers:[{url:'https://{host}/api/v1/customer-feedback',variables:{host:{default:'localhost',description:'Replace with the deployed API HTTPS host.'}}}],security:[],paths:{
 '/options':{get:{operationId:'getCustomerFeedbackOptions',summary:'Active types, brands, and brand-specific branches/topics',parameters:['brandID','typeID'].map(name=>({name,in:'query',required:false,schema:{type:'integer',minimum:0,default:0}})),responses:{200:ok('Options'),...errors}}},
 '/requests':{post:{operationId:'createCustomerFeedback',summary:'Submit customer data and optional attachments atomically',requestBody:{required:true,content:{'multipart/form-data':{schema:obj({data:ref('CustomerCreate'),files:{type:'array',maxItems:5,items:{type:'string',format:'binary'},description:'PDF or image only, 10MiB maximum per file.'}},['data']),encoding:{data:{contentType:'application/json'}}}}},responses:{200:ok('Saved'),...errors}}}
},components:{schemas}};
fs.writeFileSync(path.join(__dirname,'Customer-Feedback.openapi.json'),JSON.stringify(api,null,2)+'\n');
const payload=`{
  "OperationID":"{{operationID}}",
  "OccurredAt":"{{occurredAt}}",
  "TypeID":{{typeID}},
  "TopicID":{{topicID}},
  "BrandID":{{brandID}},
  "BranchID":{{branchID}},
  "Name":"اسم الزبون",
  "Mobile":"+962790001234",
  "Email":"customer@example.com",
  "Title":"ملاحظة حول الخدمة",
  "Details":"تفاصيل الشكوى أو الاقتراح",
  "DiscloseIdentity":true
}`;
const base='{{baseUrl}}/api/v1/customer-feedback';
const collection={info:{name:'Prosto - Customer Feedback',schema:'https://schema.getpostman.com/json/collection/v2.1.0/collection.json',description:'No login. Configure baseUrl to HTTPS. Get real catalog IDs from options. Reset operationID and occurredAt only for a NEW submission; preserve both and exact files for retries. Read Customer-Feedback-API.md.'},auth:{type:'noauth'},variable:Object.entries({baseUrl:'https://localhost',brandID:'29',branchID:'25',typeID:'1',topicID:'1',operationID:'',occurredAt:'',customerRequestID:''}).map(([key,value])=>({key,value,type:'string'})),item:[
 {name:'1 - Available types and brands',request:{method:'GET',header:[{key:'Accept',value:'application/json'}],url:base+'/options'}},
 {name:'1 - Branches and topics for selected brand/type',request:{method:'GET',header:[{key:'Accept',value:'application/json'}],url:base+'/options?brandID={{brandID}}&typeID={{typeID}}'}},
 {name:'2 - Submit customer request with files',event:[{listen:'prerequest',script:{type:'text/javascript',exec:[
  "// Clear both variables for a NEW submission; retain them unchanged for network retries.",
  "if(!pm.collectionVariables.get('operationID')) pm.collectionVariables.set('operationID',pm.variables.replaceIn('{{$guid}}'));",
  "if(!pm.collectionVariables.get('occurredAt')) pm.collectionVariables.set('occurredAt',new Date().toISOString());"]}},
 {listen:'test',script:{type:'text/javascript',exec:["if(pm.response.code===200)pm.collectionVariables.set('customerRequestID',pm.response.json().Data.RequestID);"]}}],request:{method:'POST',header:[{key:'Accept',value:'application/json'}],url:base+'/requests',body:{mode:'formdata',formdata:[{key:'data',value:payload,type:'text',contentType:'application/json'},{key:'files',type:'file',src:[],disabled:true,description:'Optional PDFs/images, up to five files, 10MiB each.'}]}}}
]};
fs.writeFileSync(path.join(__dirname,'Prosto-Customer-Feedback.postman_collection.json'),JSON.stringify(collection,null,2)+'\n');
console.log('Generated customer OpenAPI (2 operations) and Postman collection.');
