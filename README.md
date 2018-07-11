20180711

과제

- 유저는 하나의 방에 한번만 가입할 수 있도록 하는

chat_room_controller

     def user_admit_room
        # 현재 유저가 있는 방에서 join 버튼을 눌렀을 때 동작하는 액션
        # 이미 조인되어있는 유저라면
        # 이미 참가한 방입니다를 alert를 통해 알려주고
        # 아닐 경우엔 참가시킨다.
        
      	# @chat_room.users.include?(current_user)
        if current_user.joined_room?(@chat_room)
          #  -> 유저가 참가하고 있는 방의 목록 중에 이 방이 포함되어 있나?
          # current_user.chat_rooms -> 배열 형태이다.  
          # current_user.chat_rooms.where(params[:id])[0].nil? # find는 값이 없는 경우 에러를 보낸다.
          # current_user.chat_rooms.include?(@chat_room)  # 위와 동일한 내용
          #  -> 방에 참가하고 있는 유저들 중에 이 유저가 포함되어 있나??
          #   @chat_room.users.include?(current_user)
          render js: "alert('이미 참여한 방입니다.');"
        else   
          @chat_room.user_admit_room(current_user)
        end

    <% unless current_user.join_room?(@chat_room) %>
    <%= link_to 'Join', join_chat_room_path(@chat_room), method: 'post', remote: true, class: 'join_room' %> |
    <% end %>

    -- user.rb 
    def joined_room?(room)
        self.chat_rooms.include?(room)
      end

- 다른 방에 가입 내용이 뜨지 않도록 하는 작업

    ----> show
    var channel = pusher.subscribe('chat_room_<%= @chat_room.id %>'); //채널
    
    -----> admission
    def user_join_chat_room_notification
            Pusher.trigger("chat_room_#{self.chat_room_id}", 'join', {chat_room_id: self.chat_room_id, email: self.user.email}.as_json)
        end

- 채팅 내용이 뜨도록

    ----->show
    <hr>
    <div class="chat_list">
     <% @chat_room.chats.each do |chat| %>
        <p><%= chat.user.email%> : <%= chat.message %><small><%= chat.created_at %></p>
     <%end%> 
    </div>
    <%= form_tag("/chat_rooms/#{@chat_room.id}/chat", remote: true) do %> 
        <%= text_ field_tag :message %>
    <%end%>
    
    ---------> route
    post '/chat' => 'chat_rooms#chat'resources :chat_rooms do
        member do
          post '/join' => 'chat_rooms#user_admit_room', as: 'join'   
          post '/chat' => 'chat_rooms#chat'   #추가
        end
      end
    
    ----> controller
    def chat
        @chat_room.chats.create(user_id: current_user.id, message: params[:message])
      end
    
    before_action :set_chat_room, only: [:show, :edit, :update, :destroy, :user_admit_room, :chat]

views/chat_rooms/chat.js.erb파일을 만든다.

    console.log("채팅중");
    $('#message').val(''); 

models/chat.rb

     after_commit :chat_message_notification, on: :create
     
     def chat_message_notification
         Pusher.trigger("chat_room_#{self.chat_room_id}","chat",self.as_json)
     end

 show.html

    function user_chat(data){
            $('.chat_list').append(`<p>${data.user_id}: ${data.message}<small>(${data.created_at})`)
        }
    channel.bind('chat', function(data){
            user_chat(data);
        });

- 입장시 알림 서비스 + 조인 전까진 채팅할 수 없도록

    function user_joined(data){
            $('.joined_user_list').append(`${data.email}</p>`);
            $('.chat_list').append(`<p>${data.email}님께서 입장하셨습니다.</p>`);
        }
    
    
    <% if current_user.joined_room?(@chat_room) %>
    <hr>
    <div class="chat_list">
     <% @chat_room.chats.each do |chat| %>
        <p><%= chat.user.email%> : <%= chat.message %><small><%= chat.created_at %></p>
     <%end%> 
    </div>
    <!-- remote를 쓰면 ajax를 자동으로 쓸 수 있다.-->
    <%= form_tag("/chat_rooms/#{@chat_room.id}/chat", remote: true) do %>
        <%= text_field_tag :message %>
    <%end%>
    <%end%>

- 채팅방에서 나가기

show

    <% unless current_user.joined_room?(@chat_room) %>
    <span class= "join_room">
    <%= link_to 'Join', join_chat_room_path(@chat_room), method: 'post', remote: true, class: 'join_room' %> |
    </span>
    <%else%>
     <%= link_to 'Exit', exit_chat_room_path(@chat_room) , method: 'delete', remote: true, data: {confirm: "이 방을 나가시겠습니까?"} %>
    <% end %>

routes에 delete '/exit' => 'chat_rooms#user_exit_room' 를 member안에 삽입

chatroomController

      def user_exit_room
        @chat_room.user_exit_room(current_user)
      end
    
     before_action :set_chat_room, only: [:show, :edit, :update, :destroy, :user_admit_room, :chat, :user_exit_room]

chatroom.rb

        def user_exit_room(user)
            Admission.where(user_id: user.id, chat_room_id: self.id)[0].destroy
        end

views/chat_rooms/user_exit_room.js.erb파일을 만들고 

    alert('해당 채팅방에서 나왔습니다.');
    location.reload();

admission.rb ->

    after_commit :user_exit_chat_room_notification, on: :destroy
    
    def user_exit_chat_room_notification
            Pusher.trigger("c""chat_room_#{self.chat_room_id}", 'exit', self.as_json)
        end
    
    ------------------------------------------------------------------------------------------
        after_commit :user_join_chat_room_notification, on: :create
        after_commit :user_exit_chat_room_notification, on: :destroy
        
        def user_join_chat_room_notification
            Pusher.trigger("chat_room_#{self.chat_room_id}", 'join',self.as_json.merge({email: self.user.email}))
        end
        
        def user_exit_chat_room_notification
            Pusher.trigger("chat_room_#{self.chat_room_id}", 'exit', self.as_json.merge({email: self.user.email}))
        end    

############## merge

-Admission을 json화한 다음에 merge를 해야한다.

    2.4.0 :001 > self.as_json
     => {"prompt"=>{"PROMPT_I"=>"2.4.0 :%03n > ", "PROMPT_S"=>"2.4.0 :%03n%l> ", "PROMPT_C"=>"2.4.0 :%03n > ", "PROMPT_N"=>"2.4.0 :%03n?> ", "RETURN"=>" => %s \n", "AUTO_INDENT"=>true}} 
    2.4.0 :002 > u = User.first
     => #<User id: 1, email: "aa@a.a", created_at: "2018-07-10 01:41:22", updated_at: "2018-07-10 01:41:22"> 
    2.4.0 :003 > Admission.first
     => #<Admission id: 1, user_id: 1, chat_room_id: 2, created_at: "2018-07-10 01:46:38", updated_at: "2018-07-10 01:46:38"> 
    2.4.0 :005 > a=Admission.first.as_json
     => {"id"=>1, "user_id"=>1, "chat_room_id"=>2, "created_at"=>Tue, 10 Jul 2018 01:46:38 UTC +00:00, "updated_at"=>Tue, 10 Jul 2018 01:46:38 UTC +00:00} 
    2.4.0 :006 > a.merge({email: "aa@a.a", title: "1234"})
     => {"id"=>1, "user_id"=>1, "chat_room_id"=>2, "created_at"=>Tue, 10 Jul 2018 01:46:38 UTC +00:00, "updated_at"=>Tue, 10 Jul 2018 01:46:38 UTC +00:00, :email=>"aa@a.a", :title=>"1234"} 



과제

1. 현재 메인페이지(index)에서 방을 만들었을 때 방 참석인원이 0명인 상태. 어제처럼 1로 증가하게 만든다.
2. 방제 수정/삭제하는 경우에 index페이지에서 적용(pusher)될 수 있도록
3. 방을 나왔을 때 이 방의 인원을 -1해주는 것(index에서 현재 방 인원)


