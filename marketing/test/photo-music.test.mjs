import test from "node:test";
import assert from "node:assert/strict";
import { photoMusicPlan, bufferDeliveryState } from "../src/photo-music.mjs";
import { BufferPublisher } from "../src/providers/buffer.mjs";
import { MarketingOrchestrator } from "../src/orchestrator.mjs";
import { contentPresentation } from "../src/providers/review-board.mjs";

const config={PHOTO_MUSIC_MODE:"notification",AUTO_PUBLISH:true,BUFFER_INSTAGRAM_CHANNEL_ID:"ig",BUFFER_TIKTOK_CHANNEL_ID:"tt",GYMFEED_LANDING_URL:"https://gymfeed.io"};
const content={id:"photo",content_key:"GF-PHOTO",content_type:"carousel",status:"approved",asset_urls:["one.jpg","two.jpg"],decision:{content:{caption:"My training plan",hashtags:[],music_direction:"Warm upbeat instrumental with a steady groove."}}};
const music=photoMusicPlan(content,config);
function publisher(){return new BufferPublisher({apiKey:"test",baseUrl:"https://example.test",shareMode:"addToQueue",youtubePrivacy:"public"});}

test("music route is opt-in, applies to photos/carousels only and preserves the creative direction",()=>{
  assert.equal(photoMusicPlan(content,{}),null);
  assert.equal(photoMusicPlan({...content,content_type:"video"},config),null);
  assert.equal(photoMusicPlan({...content,content_type:"image"},config).required,true);
  assert.equal(music.direction,content.decision.content.music_direction);
});

for(const platform of ["instagram","tiktok"])test(`${platform} schedules native images with a music reminder, without inventing an audio field`,async()=>{
  const p=publisher(); let input;
  p.graphql=async(_q,v)=>{input=v.input;return {createPost:{post:{id:"buffer-1",status:"scheduled"}}};};
  await p.publish({platform,accountId:"channel",text:"Caption",mediaUrls:content.asset_urls,scheduledTime:"2026-12-01T18:00:00Z",music});
  assert.equal(input.schedulingType,"notification");
  assert.deepEqual(input.assets,[{image:{url:"one.jpg"}},{image:{url:"two.jpg"}}]);
  assert.doesNotMatch(input.text,/groove|Music required/);
  assert.equal(input.text.match(/AI-generated imagery/g).length,1);
  if(platform==="instagram")assert.deepEqual(input.metadata.instagram,{type:"post",shouldShareToFeed:true,stickerFields:{music:music.direction}});
  else assert.deepEqual(input.metadata,{});
});

test("video publishing remains automatic; photo music cannot be accidentally applied to a video",async()=>{
  const p=publisher();let input;
  p.graphql=async(_q,v)=>{input=v.input;return {createPost:{post:{id:"video-1"}}};};
  await assert.rejects(p.publish({platform:"instagram",isVideo:true,mediaUrls:["video.mp4"],music}),/Native photo music requires/);
  await p.publish({platform:"instagram",isVideo:true,text:"Creator story",mediaUrls:["video.mp4"]});
  assert.equal(input.schedulingType,"automatic");
  assert.equal(input.metadata.instagram.type,"reel");
  assert.equal(input.assets[0].video.url,"video.mp4");
});

test("sent reminders never become published until the owner marks them as published",()=>{
  const remote={status:"sent",schedulingType:"notification",notificationStatus:"notified"};
  const state=bufferDeliveryState(remote);
  assert.equal(state.status,"scheduled");
  assert.equal(state.delivery.user_action_required,true);
  assert.equal(state.delivery.music_status,"add_music_in_app");
  assert.equal(bufferDeliveryState({...remote,notificationStatus:"markedAsPublished"}).status,"published");
  assert.equal(bufferDeliveryState({status:"sent",schedulingType:"automatic"}).status,"published");
  assert.equal(bufferDeliveryState({post:remote}).status,"scheduled");
  assert.equal(bufferDeliveryState({...remote,status:"draft"}).status,"pending");
  assert.equal(bufferDeliveryState({...remote,status:"failed"}).status,"failed");
});

test("notification refresh retains actionable delivery state instead of marking the content published",async()=>{
  const row={id:"pub-1",content_id:"photo",platform:"instagram",provider_request_id:"buffer-1",status:"scheduled",platform_copy:{photo_music:music,delivery:{scheduling_type:"notification"}}};
  let current=row;let parentUpdates=0;
  const orchestrator=new MarketingOrchestrator({config,repository:{pendingPublications:async()=>[current],updatePublication:async(_id,patch)=>(current={...current,...patch}),publicationByContent:async()=>[current],updateContent:async()=>parentUpdates++},publisher:{getPost:async()=>({id:"buffer-1",status:"sent",notificationStatus:"notified"})}});
  await orchestrator.refreshPublications();
  assert.equal(parentUpdates,0);
  assert.equal(current.status,"scheduled");
  assert.equal(current.platform_copy.delivery.user_action_required,true);
  const view=contentPresentation({...content,status:"scheduled",publications:[current]});
  assert.equal(view.status,"Action required: add music");
  assert.match(view.reason,/finish publishing/);
  assert.match(view.bufferStatus,/add music and publish in app/);
});

test("approved music carousel keeps all slides and reuses existing Buffer IDs on a second submission",async()=>{
  let current=structuredClone(content); const rows=new Map(); const requests=[];
  const orchestrator=new MarketingOrchestrator({config,repository:{contentById:async()=>current,brandConfig:async()=>({enabled:true}),publicationByContent:async()=>[...rows.values()],upsertPublication:async row=>{rows.set(row.platform,row);return row;},updateContent:async(_id,patch)=>(current={...current,...patch})},publisher:{publish:async request=>{requests.push(request);return {id:`buffer-${request.platform}`};}}});
  await orchestrator.publishContent(content.id);
  await orchestrator.publishContent(content.id);
  assert.equal(requests.length,2);
  for(const request of requests){assert.equal(request.isVideo,false);assert.deepEqual(request.mediaUrls,content.asset_urls);assert.equal(request.music.direction,music.direction);}
  for(const row of rows.values())assert.equal(row.platform_copy.delivery.scheduling_type,"notification");
});

test("CMO metrics and benchmarks exclude sent notifications that have not been marked published",async()=>{
  const p=publisher();
  p.benchmarkPostIds=["reminder","outside-reminder"];
  p.listChannels=async()=>[{organizationId:"org"}];
  p.graphql=async()=>({posts:{edges:[{node:{id:"reminder",channelService:"instagram",status:"sent",schedulingType:"notification",notificationStatus:"notified",metrics:[]}},{node:{id:"live",channelService:"instagram",status:"sent",schedulingType:"automatic",metrics:[]}}]}});
  p.getPost=async id=>{assert.equal(id,"outside-reminder");return {id,schedulingType:"notification",notificationStatus:"notified",metrics:[]};};
  const result=await p.performanceSummary();
  assert.equal(result.posts_analyzed,1);
  assert.deepEqual(result.benchmark_posts,[]);
});
