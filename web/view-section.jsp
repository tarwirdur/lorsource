<%@ page pageEncoding="koi8-r" contentType="text/html; charset=utf-8"%>
<%@ page import="java.io.File" errorPage="/error.jsp" %>
<%@ page import="java.io.IOException"%>
<%@ page import="java.net.URLEncoder" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.logging.Logger" %>
<%@ page import="javax.mail.Session" %>
<%@ page import="javax.mail.Transport" %>
<%@ page import="javax.mail.internet.InternetAddress" %>
<%@ page import="javax.mail.internet.MimeMessage" %>
<%@ page import="javax.servlet.http.Cookie" %>
<%@ page import="javax.servlet.http.HttpServletResponse" %>
<%@ page import="org.apache.commons.fileupload.FileItem" %>
<%@ page import="org.apache.commons.fileupload.disk.DiskFileItemFactory" %>
<%@ page import="org.apache.commons.fileupload.servlet.ServletFileUpload" %>
<%@ page import="org.apache.commons.lang.StringUtils" %>
<%@ page import="ru.org.linux.boxlet.BoxletVectorRunner" %>
<%@ page import="ru.org.linux.site.*" %>
<%@ page import="ru.org.linux.storage.StorageNotFoundException" %>
<%@ page import="ru.org.linux.util.*" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>

<% Template tmpl = new Template(request, config, response);%>
<%= tmpl.head() %>
<%

  response.setDateHeader("Expires", new Date(new Date().getTime() - 20 * 3600 * 1000).getTime());
  response.setDateHeader("Last-Modified", new Date(new Date().getTime() - 2 * 1000).getTime());

  int sectionid = tmpl.getParameters().getInt("section");

  Connection db = null;
  try {
    db = tmpl.getConnection();

    Section section = new Section(db, sectionid);

    if (!section.isBrowsable()) {
      throw new BadSectionException(sectionid);
    }
%>
<c:set var="section" value="<%= section %>"/>

<title>${section.name}</title>
<link rel="parent" title="Linux.org.ru" href="/">
<LINK REL="alternate" HREF="section-rss.jsp?section=${section.id}" TYPE="application/rss+xml">
<%= tmpl.DocumentHeader() %>
  <table class=nav>
    <tr>
      <td align=left valign=middle>
        <strong>${section.name}</strong>
      </td>

      <td align=right valign=middle>
        [<a href="add-section.jsp?section=${section.id}">${section.addText}</a>]
        
        [<a href="tracker.jsp">��������� ���������</a>]

        <c:if test="${section.forum}">
          [<a href="rules.jsp">������� ������</a>]
        </c:if>

        [<a href="section-rss.jsp?section=${section.id}">RSS</a>]
      </td>
    </tr>
  </table>

<h1>${section.name}</h1>

������:
<ul>

  <c:forEach var="group"
             items="<%= Group.getGroups(db, section) %>">
    <li>
      <a href="${group.url}">${group.title}</a>

      (${group.stat1}/${group.stat2}/${group.stat3})

      <c:if test="${group.info != null}">
        - <em><c:out value="${group.info}" escapeXml="false"/></em>
      </c:if>

    </li>

  </c:forEach>

</ul>

<%
  } finally {
    if (db!=null) {
      db.close();
    }
  }
%>

<c:if test="${section.forum}">
<h1>���������</h1>
���� �� ��� �� ������������������ - ��� <a href="register.jsp">����</a>.
<ul>
<li><a href="addphoto.jsp">�������� ����������</a>
<li><a href="register.jsp?mode=change">��������� �����������</a>
<li><a href="lostpwd.jsp">�������� ������� ������</a>
<li><a href="edit-profile.jsp">������������ ��������� �����</a>
</ul>
</c:if>

<%= tmpl.DocumentFooter() %>
