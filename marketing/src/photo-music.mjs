const normalize=value=>String(value??"").toLowerCase().replace(/[^a-z]/g,"");
export function photoMusicPlan(content,config){
  if(content.content_type==="video"||config.PHOTO_MUSIC_MODE!=="notification")return null;
  return {version:1,required:true,scheduling_type:"notification",direction:content.decision?.content?.music_direction?.trim()
    ||"Instrumental fitness groove, warm confident energy, clear steady beat, no vocals. Choose a track available for this business account in the app.",
    action:"Open the Buffer mobile notification, add music in Instagram/TikTok, and finish publishing the original photo or carousel."};
}
export function photoMusicMessage(music){
  return `Music required: ${music.direction} Approve schedules a Buffer mobile notification; add the track and finish publishing in the Instagram/TikTok app. This is not automatic publication.`;
}
export function bufferDeliveryState(remote,publication={},now=Date.now()){
  remote=remote.post??remote;
  const status=normalize(remote.status??"sending");
  const schedulingType=remote.schedulingType??publication.platform_copy?.delivery?.scheduling_type??"automatic";
  const notificationStatus=remote.notificationStatus??publication.platform_copy?.delivery?.notification_status??null;
  const isNotification=schedulingType==="notification";
  const marked=normalize(notificationStatus)==="markedaspublished";
  const error=["failed","error"].includes(status);
  const sent=["sent","published","success","succeeded"].includes(status);
  const due=Date.parse(remote.dueAt??publication.scheduled_at??"");
  const pending=["draft","needsapproval"].includes(status);
  const actionRequired=isNotification&&!marked&&!error&&!pending&&(sent||normalize(notificationStatus)==="notified"||Number.isFinite(due)&&due<=now);
  return {status:error?"failed":pending?"pending":isNotification?(marked?"published":"scheduled"):sent?"published":status==="scheduled"?"scheduled":"publishing",
    delivery:{...publication.platform_copy?.delivery,scheduling_type:schedulingType,notification_status:notificationStatus,user_action_required:actionRequired,
      music_status:isNotification?(marked?"owner_marked_published":pending?"not_scheduled":actionRequired?"add_music_in_app":"scheduled_music_notification"):publication.platform_copy?.delivery?.music_status??null}};
}
