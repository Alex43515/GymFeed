import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/supabase/repositories/profile_repository.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'follower_componant_model.dart';
export 'follower_componant_model.dart';

class FollowerComponantWidget extends StatefulWidget {
  const FollowerComponantWidget({
    super.key,
    this.users,
    this.onRelationshipChanged,
  });

  final DocumentReference? users;
  final Future<void> Function()? onRelationshipChanged;

  @override
  State<FollowerComponantWidget> createState() =>
      _FollowerComponantWidgetState();
}

class _FollowerComponantWidgetState extends State<FollowerComponantWidget> {
  late FollowerComponantModel _model;
  bool _isFollowing = false;
  bool _followsYou = false;
  bool _isLoadingRelationship = true;
  bool _isUpdatingRelationship = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => FollowerComponantModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRelationship());
  }

  Future<void> _loadRelationship() async {
    final targetId = widget.users?.id ?? '';
    if (targetId.isEmpty || targetId == currentUserUid) {
      if (mounted) safeSetState(() => _isLoadingRelationship = false);
      return;
    }
    final state = await ProfileRepository().socialState(targetId);
    if (!mounted) return;
    safeSetState(() {
      _isFollowing = state.isFollowing;
      _followsYou = state.followsYou;
      _isLoadingRelationship = false;
    });
  }

  Future<void> _toggleRelationship() async {
    final targetId = widget.users?.id ?? '';
    if (targetId.isEmpty || _isUpdatingRelationship) return;
    final wasFollowing = _isFollowing;
    safeSetState(() {
      _isFollowing = !wasFollowing;
      _isUpdatingRelationship = true;
    });
    var succeeded = false;
    try {
      if (wasFollowing) {
        await ProfileRepository().unfollow(targetId);
      } else {
        await ProfileRepository().follow(targetId);
      }
      await refreshCurrentUserProfile();
      succeeded = true;
      if (mounted) {
        final state = await ProfileRepository().socialState(targetId);
        if (mounted) {
          safeSetState(() {
            _isFollowing = state.isFollowing;
            _followsYou = state.followsYou;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        safeSetState(() => _isFollowing = wasFollowing);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update follow. Try again.')),
        );
      }
    } finally {
      if (mounted) safeSetState(() => _isUpdatingRelationship = false);
    }
    if (succeeded) {
      try {
        await widget.onRelationshipChanged?.call();
      } catch (_) {
        // The relationship is already persisted. A list refresh failure should
        // not roll the button back or report that the follow itself failed.
      }
    }
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
      child: StreamBuilder<UsersRecord>(
        stream: UsersRecord.getDocument(widget.users!),
        builder: (context, snapshot) {
          // Customize what your widget looks like when it's loading.
          if (!snapshot.hasData) {
            return Center(
              child: SizedBox(
                width: 12.0,
                height: 12.0,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white,
                  ),
                ),
              ),
            );
          }

          final rowUsersRecord = snapshot.data!;

          return InkWell(
            splashColor: Colors.transparent,
            focusColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              if (rowUsersRecord.reference == currentUserReference) {
                context.pushNamed(ProfileWidget.routeName);
              } else {
                context.pushNamed(
                  ProfileOtherWidget.routeName,
                  queryParameters: {
                    'username': serializeParam(
                      rowUsersRecord.username,
                      ParamType.String,
                    ),
                  }.withoutNulls,
                );
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 55.0,
                  height: 55.0,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    valueOrDefault<String>(
                      rowUsersRecord.photoUrl,
                      'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 0.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rowUsersRecord.username.maybeHandleOverflow(
                            maxChars: 18,
                            replacement: '…',
                          ),
                          maxLines: 1,
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    fontFamily: 'Poppins',
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                  ),
                        ),
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              0.0, 2.0, 0.0, 0.0),
                          child: Text(
                            rowUsersRecord.displayName.maybeHandleOverflow(
                              maxChars: 20,
                              replacement: '…',
                            ),
                            maxLines: 1,
                            style:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      fontFamily: 'Poppins',
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 6.0, 0.0),
                  child: rowUsersRecord.uid == currentUserUid
                      ? const SizedBox.shrink()
                      : InkWell(
                          splashColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap:
                              _isLoadingRelationship || _isUpdatingRelationship
                                  ? null
                                  : _toggleRelationship,
                          child: Container(
                            width: 110.0,
                            height: 35.0,
                            decoration: BoxDecoration(
                              color: _isFollowing
                                  ? const Color(0xFFEFEFEF)
                                  : FlutterFlowTheme.of(context).primary,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            alignment: const AlignmentDirectional(0.0, 0.0),
                            child: Text(
                              _isLoadingRelationship || _isUpdatingRelationship
                                  ? 'Updating...'
                                  : _isFollowing
                                      ? 'Following'
                                      : _followsYou
                                          ? 'Follow back'
                                          : 'Follow',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    fontFamily: 'Poppins',
                                    color:
                                        FlutterFlowTheme.of(context).secondary,
                                    fontSize: 13.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
