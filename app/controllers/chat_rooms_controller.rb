class ChatRoomsController < ApplicationController
  before_action :set_chat_room, only: [:show, :edit, :update, :destroy, :user_admit_room, :chat, :user_exit_room]
  before_action :authenticate_user!, except: [:index]
  # GET /chat_rooms
  # GET /chat_rooms.json
  def index
    @chat_rooms = ChatRoom.all
  end

  # GET /chat_rooms/1
  # GET /chat_rooms/1.json
  def show
  end

  # GET /chat_rooms/new
  def new
    @chat_room = ChatRoom.new
  end

  # GET /chat_rooms/1/edit
  def edit
  end

  # POST /chat_rooms
  # POST /chat_rooms.json
  def create
    @chat_room = ChatRoom.new(chat_room_params)
    @chat_room.master_id = current_user.email
    respond_to do |format|
      if @chat_room.save
        # 챗룸으로 만들어진 인스턴스 메소드이기 때문에 Chat이 아니라 @chat이다.
        @chat_room.user_admit_room(current_user)
        format.html { redirect_to @chat_room, notice: 'Chat room was successfully created.' }
        format.json { render :show, status: :created, location: @chat_room }
      else
        format.html { render :new }
        format.json { render json: @chat_room.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /chat_rooms/1
  # PATCH/PUT /chat_rooms/1.json
  def update
    respond_to do |format|
      if @chat_room.update(chat_room_params)
        format.html { redirect_to @chat_room, notice: 'Chat room was successfully updated.' }
        format.json { render :show, status: :ok, location: @chat_room }
      else
        format.html { render :edit }
        format.json { render json: @chat_room.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /chat_rooms/1
  # DELETE /chat_rooms/1.json
  def destroy
    respond_to do |format|
      if @chat_room.master_id == current_user.id
        format.html { redirect_to chat_rooms_url, notice: 'Chat room was successfully destroyed.' }
        format.json { head :no_content }
        @chat_room.master_id = @chat_room.users.user_id.sample()
      end
      @chat_room.authenticate_user.size -= 1
      @chat_room.destroy
    end
  end
  
  def user_admit_room
    # 현재 유저가 있는 방에서 join 버튼을 눌렀을 때 동작하는 액션
    # 이미 조인되어있는 유저라면
    # 이미 참가한 방입니다를 alert를 통해 알려주고
    # 아닐 경우엔 참가시킨다.
    
    if current_user.joined_room?(@chat_room)
      #  -> 유저가 참가하고 있는 방의 목록 중에 이 방이 포함되어 있나?
      #  current_user.chat_rooms -> 배열 형태이다.  
      # current_user.chat_rooms.where(params[:id])[0].nil? # find는 값이 없는 경우 에러를 보낸다.
      # current_user.chat_rooms.include?(@chat_room)  # 위와 동일한 내용
      #  -> 방에 참가하고 있는 유저들 중에 이 유저가 포함되어 있나??
      #   @chat_room.users.include?(current_user)
      render js: "alert('이미 참여한 방입니다.');"
    else   
      @chat_room.user_admit_room(current_user)
    end
  end

  def chat
    @chat_room.chats.create(user_id: current_user.id, message: params[:message])
  end
  
  def user_exit_room
    @chat_room.user_exit_room(current_user)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_chat_room
      @chat_room = ChatRoom.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def chat_room_params
      params.fetch(:chat_room, {}).permit(:title, :max_count)
    end
  
end
