/*
 * Copyright 1998-2022 Linux.org.ru
 *    Licensed under the Apache License, Version 2.0 (the "License");
 *    you may not use this file except in compliance with the License.
 *    You may obtain a copy of the License at
 *
 *        http://www.apache.org/licenses/LICENSE-2.0
 *
 *    Unless required by applicable law or agreed to in writing, software
 *    distributed under the License is distributed on an "AS IS" BASIS,
 *    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *    See the License for the specific language governing permissions and
 *    limitations under the License.
 */

package ru.org.linux.user

import org.springframework.stereotype.Service
import ru.org.linux.group.GroupDao
import ru.org.linux.markup.MessageTextService
import ru.org.linux.section.SectionService
import ru.org.linux.spring.dao.{DeleteInfoDao, MsgbaseDao}
import ru.org.linux.topic.TopicTagService

import scala.jdk.CollectionConverters._
import scala.jdk.OptionConverters.RichOptional

@Service
class UserEventPrepareService(msgbaseDao: MsgbaseDao, messageTextService: MessageTextService, userService: UserService,
                              deleteInfoDao: DeleteInfoDao, sectionService: SectionService, groupDao: GroupDao,
                              tagService: TopicTagService) {
  /**
   * @param events      список событий
   * @param readMessage возвращать ли отрендеренное содержимое уведомлений (используется только для RSS)
   */
  def prepare(events: java.util.List[UserEvent], readMessage: Boolean): java.util.List[PreparedUserEvent] = {
    val evts = events.asScala

    val userIds = (evts.map(_.getCommentAuthor) ++ evts.map(_.getTopicAuthor)).filter(_ != 0)

    val users = userService.getUsersCachedMap(userIds)

    val tags = tagService.tagRefs(evts.map(_.getTopicId).distinct).view.mapValues(_.map(_.name))

    val prepared = evts.map { event =>
      val msgid = if (event.isComment) event.getCid else event.getTopicId

      val text = if (readMessage) {
        val messageText = msgbaseDao.getMessageText(msgid)

        Some(messageTextService.renderTextRSS(messageText))
      } else {
        None
      }

      val topicAuthor = users(event.getTopicAuthor)

      val commentAuthor = if (event.isComment) {
        users.get(event.getCommentAuthor)
      } else {
        None
      }

      val bonus = (if ("DEL" == event.getType.getType) {
        deleteInfoDao.getDeleteInfo(msgid).toScala
      } else {
        None
      }).map(_.getBonus)

      val group = groupDao.getGroup(event.getGroupId)

      PreparedUserEvent(
        event = event,
        messageText = text,
        topicAuthor = topicAuthor,
        commentAuthor = commentAuthor,
        bonus = bonus,
        section = sectionService.getSection(group.getSectionId),
        group = group,
        tags = tags.getOrElse(event.getTopicId, Seq.empty).take(TopicTagService.MaxTagsInTitle).toSeq
      )
    }

    prepared.asJava
  }
}
